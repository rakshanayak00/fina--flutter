/*
 * DeepChildShield - ESP32 Hardware Controller
 * 
 * Hardware Configuration:
 * 1. ESP32 Dev Module <--> PCA9685 I2C Servo Driver:
 *    - 3V3       -> VCC (Logic Power)
 *    - GND       -> GND
 *    - GPIO 21   -> SDA
 *    - GPIO 22   -> SCL
 *    - External 5V Power Supply -> V+ & GND on PCA9685 terminal block (For servos)
 *
 * 2. Servo Motors (Safety Barriers / Window Gates):
 *    - Servo 1   -> PCA9685 Channel 0 (e.g. Window Shield Gate)
 *    - Servo 2   -> PCA9685 Channel 1 (e.g. Balcony Barrier)
 *    - Servo 3   -> PCA9685 Channel 2 (e.g. Staircase Safety Gate)
 *
 * 3. Alert Buzzer:
 *    - Buzzer (+) -> ESP32 GPIO 25
 *    - Buzzer (-) -> GND
 *
 * Communication:
 *    - USB Serial (115200 baud) or Wi-Fi HTTP / Socket
 *    - Commands received:
 *      * "ALERT:ON" or "ALERT_ZONE:BUZZER_ON" -> Activates Buzzer & closes all servo barriers
 *      * "ALERT:OFF" or "SAFE"                -> Disengages buzzer & retracts barriers
 *      * "SERVO:<channel>:<angle>"            -> Direct angle control (e.g. "SERVO:0:90")
 *      * "BUZZER:1" / "BUZZER:0"              -> Manual buzzer control
 *      * "STATUS"                             -> Returns current hardware state
 */

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

// Initialize PCA9685 at default I2C address 0x40
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

// Servo pulse configuration (SG90 / MG995 / MG996R typical 50Hz values)
#define SERVO_FREQ 50      // 50 Hz analog servo
#define SERVOMIN   125     // Minimum pulse length out of 4096 (approx 0 degrees)
#define SERVOMAX   575     // Maximum pulse length out of 4096 (approx 180 degrees)

// Hardware Pins
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22
#define BUZZER_PIN  25

// Channels on PCA9685
#define SERVO_CH_0 0
#define SERVO_CH_1 1
#define SERVO_CH_2 2

// State flags
bool alertActive = false;
unsigned long buzzerBeepTimer = 0;
bool buzzerBeepState = false;

// Helper function to map 0 - 180 degrees to PCA9685 pulse width
int angleToPulse(int angle) {
  angle = constrain(angle, 0, 180);
  return map(angle, 0, 180, SERVOMIN, SERVOMAX);
}

void setServoAngle(uint8_t channel, int angle) {
  int pulse = angleToPulse(angle);
  pwm.setPWM(channel, 0, pulse);
}

// Deploy protective barriers when child approaches danger zone
void deploySafetyBarriers() {
  Serial.println("[ESP32] >>> DEPLOYING SAFETY BARRIERS (Servos Engaged) <<<");
  setServoAngle(SERVO_CH_0, 90);  // Close barrier 1
  setServoAngle(SERVO_CH_1, 90);  // Close barrier 2
  setServoAngle(SERVO_CH_2, 90);  // Close barrier 3
}

// Retract barriers when safe
void retractSafetyBarriers() {
  Serial.println("[ESP32] >>> RETRACTING BARRIERS (Servos Disengaged) <<<");
  setServoAngle(SERVO_CH_0, 0);   // Retract barrier 1
  setServoAngle(SERVO_CH_1, 0);   // Retract barrier 2
  setServoAngle(SERVO_CH_2, 0);   // Retract barrier 3
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n==========================================");
  Serial.println("  DeepChildShield - ESP32 Hardware Guard  ");
  Serial.println("==========================================");

  // Initialize Buzzer
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // Initialize I2C (GPIO 21 SDA, GPIO 22 SCL)
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);

  // Initialize PCA9685 PWM Driver
  pwm.begin();
  pwm.setOscillatorFrequency(27000000);
  pwm.setPWMFreq(SERVO_FREQ);
  delay(100);

  // Test sequence: Retract barriers initially
  retractSafetyBarriers();

  // Test beep buzzer
  digitalWrite(BUZZER_PIN, HIGH);
  delay(150);
  digitalWrite(BUZZER_PIN, LOW);

  Serial.println("[ESP32] System Ready. Awaiting commands from Flask Backend...");
}

void parseCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  Serial.print("[ESP32 Command Received]: ");
  Serial.println(cmd);

  // Danger Zone Alert Triggered
  if (cmd.indexOf("ALERT") >= 0 || cmd.indexOf("BUZZER_ON") >= 0) {
    alertActive = true;
    deploySafetyBarriers();
    Serial.println("[ESP32 Response]: ALERT_ACTIVE:BUZZER_ON:BARRIER_DEPLOYED");
  }
  // Safe / Normal State
  else if (cmd.indexOf("SAFE") >= 0 || cmd.indexOf("BUZZER_OFF") >= 0 || cmd == "ALERT:OFF") {
    alertActive = false;
    digitalWrite(BUZZER_PIN, LOW);
    retractSafetyBarriers();
    Serial.println("[ESP32 Response]: STATUS_SAFE:BARRIER_RETRACTED");
  }
  // Direct Servo Command format: SERVO:<channel>:<angle>
  else if (cmd.startsWith("SERVO:")) {
    int firstColon = cmd.indexOf(':');
    int secondColon = cmd.indexOf(':', firstColon + 1);
    if (secondColon > 0) {
      int ch = cmd.substring(firstColon + 1, secondColon).toInt();
      int angle = cmd.substring(secondColon + 1).toInt();
      if (ch >= 0 && ch <= 2) {
        setServoAngle(ch, angle);
        Serial.printf("[ESP32 Response]: SERVO %d SET TO %d DEG\n", ch, angle);
      }
    }
  }
  // Direct Buzzer Manual Command
  else if (cmd == "BUZZER:1") {
    alertActive = true;
  }
  else if (cmd == "BUZZER:0") {
    alertActive = false;
    digitalWrite(BUZZER_PIN, LOW);
  }
  else if (cmd == "STATUS") {
    Serial.printf("[ESP32 Status]: alert=%d, buzzer_pin=25, pca9685=0x40\n", alertActive ? 1 : 0);
  }
}

void loop() {
  // Read serial commands from Flask Backend
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    parseCommand(command);
  }

  // Pulsing Alarm Sound when child is in danger zone
  if (alertActive) {
    unsigned long currentMillis = millis();
    if (currentMillis - buzzerBeepTimer >= 150) {
      buzzerBeepTimer = currentMillis;
      buzzerBeepState = !buzzerBeepState;
      digitalWrite(BUZZER_PIN, buzzerBeepState ? HIGH : LOW);
    }
  }
}
