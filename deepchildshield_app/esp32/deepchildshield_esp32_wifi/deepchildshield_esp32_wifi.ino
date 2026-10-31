/*
 * DeepChildShield - Standalone ESP32 Wi-Fi Hardware Controller
 * 
 * Works completely independently on BATTERY (NO laptop USB cable needed).
 * Connects to your Phone / Wi-Fi Hotspot via Wi-Fi and polls the alerts directly!
 *
 * Hardware Wiring:
 * 1. ESP32 Dev Module <--> PCA9685 I2C Servo Driver:
 *    - 3V3       -> VCC (Logic Power)
 *    - GND       -> GND (Common Ground)
 *    - GPIO 21   -> SDA
 *    - GPIO 22   -> SCL
 *    - Battery (5V-6V) -> V+ & GND terminal block on PCA9685 (For 3 Servos)
 *    - Battery (5V via VIN or 3.7V LiPo with boost) -> VIN & GND on ESP32
 *
 * 2. Servo Motors (Safety Barriers):
 *    - Servo 1   -> PCA9685 Channel 0 (Window Shield)
 *    - Servo 2   -> PCA9685 Channel 1 (Balcony Gate)
 *    - Servo 3   -> PCA9685 Channel 2 (Staircase Barrier)
 *
 * 3. Alert Buzzer:
 *    - Buzzer (+) -> ESP32 GPIO 25
 *    - Buzzer (-) -> GND
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

// ============================================================
// 1. CONFIGURE YOUR HOTSPOT / WI-FI DETAILS HERE:
// ============================================================
const char* WIFI_SSID     = "YOUR_HOTSPOT_NAME";       // Change to your Phone Hotspot name
const char* WIFI_PASSWORD = "YOUR_HOTSPOT_PASSWORD";   // Change to your Phone Hotspot password

// Backend Server IP (where Flask YOLO is running, e.g., your laptop or hotspot IP)
const char* BACKEND_HOST  = "http://192.168.29.217:5001/api/alerts";

// ============================================================
// HARDWARE DEFINITIONS
// ============================================================
#define I2C_SDA_PIN 21
#define I2C_SCL_PIN 22
#define BUZZER_PIN  25

#define SERVO_CH_0  0
#define SERVO_CH_1  1
#define SERVO_CH_2  2

#define SERVO_FREQ  50
#define SERVOMIN    125    // 0 degrees
#define SERVOMAX    575    // 180 degrees

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

bool alertActive = false;
unsigned long buzzerTimer = 0;
bool buzzerState = false;
unsigned long lastPollTime = 0;
String lastAlertTimestamp = "";

int angleToPulse(int angle) {
  angle = constrain(angle, 0, 180);
  return map(angle, 0, 180, SERVOMIN, SERVOMAX);
}

void setServoAngle(uint8_t channel, int angle) {
  pwm.setPWM(channel, 0, angleToPulse(angle));
}

// Deploy 3 servo protective barriers
void deploySafetyBarriers() {
  setServoAngle(SERVO_CH_0, 90);
  setServoAngle(SERVO_CH_1, 90);
  setServoAngle(SERVO_CH_2, 90);
}

// Retract barriers to safe position
void retractSafetyBarriers() {
  setServoAngle(SERVO_CH_0, 0);
  setServoAngle(SERVO_CH_1, 0);
  setServoAngle(SERVO_CH_2, 0);
}

void connectToWiFi() {
  Serial.print("\n[ESP32] Connecting to Wi-Fi Hotspot: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 20) {
    delay(500);
    Serial.print(".");
    tries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[ESP32] Connected to Hotspot Successfully!");
    Serial.print("[ESP32] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[ESP32] Wi-Fi connection failed. Will retry in loop.");
  }
}

void setup() {
  Serial.begin(115200);

  // Buzzer Setup
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // I2C Setup for PCA9685
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  pwm.begin();
  pwm.setOscillatorFrequency(27000000);
  pwm.setPWMFreq(SERVO_FREQ);
  delay(100);

  // Initial barrier state (Open / Retracted)
  retractSafetyBarriers();

  // Beep once to show battery power is ON
  digitalWrite(BUZZER_PIN, HIGH);
  delay(200);
  digitalWrite(BUZZER_PIN, LOW);

  // Connect to Hotspot
  connectToWiFi();
}

void checkDangerAlertsFromCloud() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
    return;
  }

  HTTPClient http;
  http.begin(BACKEND_HOST);
  http.setTimeout(2500);

  int httpCode = http.GET();
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    
    // Parse JSON response
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, payload);

    if (!error && doc.is<JsonArray>() && doc.size() > 0) {
      JsonObject latest = doc[0];
      const char* status = latest["status"];
      const char* timestamp = latest["timestamp"];
      const char* zone = latest["danger_zone"];

      if (status && strcmp(status, "danger") == 0) {
        // Child detected in danger zone!
        if (!alertActive) {
          alertActive = true;
          Serial.printf("[🚨 STANDALONE ALERT] Child in %s! Deploying Servos & Sounding Buzzer!\n", zone ? zone : "Danger Spot");
          deploySafetyBarriers();
        }
      } else {
        if (alertActive) {
          alertActive = false;
          digitalWrite(BUZZER_PIN, LOW);
          retractSafetyBarriers();
          Serial.println("[SAFE] Child is safe. Retracting servos.");
        }
      }
    }
  } else {
    // If request fails or server timed out
    Serial.printf("[HTTP] Failed, error: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();
}

void loop() {
  unsigned long now = millis();

  // Check alerts over Wi-Fi every 1.5 seconds
  if (now - lastPollTime >= 1500) {
    lastPollTime = now;
    checkDangerAlertsFromCloud();
  }

  // Pulsing Alarm Sound while danger is active
  if (alertActive) {
    if (now - buzzerTimer >= 150) {
      buzzerTimer = now;
      buzzerState = !buzzerState;
      digitalWrite(BUZZER_PIN, buzzerState ? HIGH : LOW);
    }
  }
}
