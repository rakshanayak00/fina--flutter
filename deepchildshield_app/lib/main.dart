import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void startForegroundMonitoringCallback() {
  FlutterForegroundTask.setTaskHandler(ChildShieldTaskHandler());
}

class ChildShieldTaskHandler extends TaskHandler {
  int _lastSeenAlertId = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _checkDangerAlerts();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _checkDangerAlerts();
  }

  Future<void> _checkDangerAlerts() async {
    try {
      final url = Uri.parse('http://$appServerHost/api/alerts');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final latest = list.first;
          final int alertId = latest['id'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
          final String zone = latest['zone'] ?? 'Danger Zone';
          final conf = latest['confidence'] != null ? '${(latest['confidence'] * 100).toInt()}%' : '';

          if (alertId != _lastSeenAlertId) {
            _lastSeenAlertId = alertId;

            final androidDetails = AndroidNotificationDetails(
              'danger_zone_channel',
              'Danger Zone Alerts',
              channelDescription: 'High priority alerts when child enters danger zone',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true,
            );
            final notifDetails = NotificationDetails(android: androidDetails);
            await flutterLocalNotificationsPlugin.show(
              id: 9999,
              title: '🚨 DANGER ZONE ALERT: $zone!',
              body: 'Child is inside danger area $zone ($conf)! Take action now!',
              notificationDetails: notifDetails,
            );

            FlutterForegroundTask.updateService(
              notificationTitle: '🚨 CRITICAL: CHILD IN DANGER ZONE ($zone)!',
              notificationText: 'Tap to view live monitoring camera immediately',
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

Future<void> initForegroundService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'child_monitor_live_service',
      channelName: 'DeepChildShield Live Guard',
      channelDescription: 'Continuous background monitoring for child safety',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(3000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> startBackgroundMonitoringService() async {
  try {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 501,
        notificationTitle: '🛡️ DeepChildShield Protection Active',
        notificationText: 'Live monitoring camera & danger zones in background',
        callback: startForegroundMonitoringCallback,
      );
    }
  } catch (_) {}
}

Future<void> showSystemNotification({required String title, required String body}) async {
  final androidDetails = AndroidNotificationDetails(
    'danger_zone_channel',
    'Danger Zone Alerts',
    channelDescription: 'High priority alerts when child enters danger zone',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
  );
  final notifDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: notifDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  initForegroundService();
  startBackgroundMonitoringService();

  final prefs = await SharedPreferences.getInstance();
  final savedUser = prefs.getString('saved_user_name');

  runApp(DeepChildShieldApp(initialUser: savedUser));
}

// ===================================
// APP
// ============================================================

class DeepChildShieldApp extends StatelessWidget {
  final String? initialUser;
  const DeepChildShieldApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeepChildShield',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123B6D),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      ),
      home: initialUser != null ? HomeScreen(userName: initialUser!) : const LoginScreen(),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

const Color navy = Color(0xFF123B6D);
const Color blue = Color(0xFF1E63A5);
const Color lightBlue = Color(0xFFEAF3FB);
const Color background = Color(0xFFF5F8FC);
const Color textDark = Color(0xFF1B2635);
const Color textGrey = Color(0xFF687789);
const Color dangerRed = Color(0xFFD93434);
const Color safeGreen = Color(0xFF198754);

// Global backend address (supports both emulator 127.0.0.1 and physical phone on Wi-Fi)
String appServerHost = '192.168.29.217:5001';
String get apiBaseUrl => 'http://$appServerHost';

// ============================================================
// TEMPORARY LOCAL ACCOUNT STORAGE
// ============================================================

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  static String get apiBase => apiBaseUrl;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter your email and password.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        final userName = user['name'] ?? 'Parent';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_user_name', userName);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: userName,
            ),
          ),
        );
      } else {
        showMessage(data['error'] ?? 'Invalid email or password.');
      }
    } catch (e) {
      showMessage('Cannot connect to server. Check Flask backend.');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 35),
          child: Column(
            children: [
              const SizedBox(height: 25),

              const DCameraLogo(size: 100),

              const SizedBox(height: 18),

              const BrandName(),

              const SizedBox(height: 45),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sign in to continue protecting your child.',
                  style: TextStyle(
                    fontSize: 15,
                    color: textGrey,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              InputBox(
                controller: emailController,
                label: 'Gmail',
                hint: 'Enter your Gmail address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              InputBox(
                controller: passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              MainButton(
                text: 'LOGIN',
                icon: Icons.login,
                onPressed: login,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              const BottomTagline(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER SCREEN
// ============================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    final mobileRegex = RegExp(r'^[6-9][0-9]{9}$');

    if (name.isEmpty) {
      showMessage('Please enter your name.');
      return;
    }
    if (!gmailRegex.hasMatch(email)) {
      showMessage('Please enter a valid Gmail address.');
      return;
    }
    if (!mobileRegex.hasMatch(mobile)) {
      showMessage('Enter a valid 10-digit mobile number.');
      return;
    }
    if (password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        showMessage('Registration successful. Please log in.');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) Navigator.pop(context);
      } else {
        showMessage(data['error'] ?? 'Registration failed.');
      }
    } catch (e) {
      showMessage('Cannot connect to server. Check Flask backend.');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Create Account',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          children: [
            const SizedBox(height: 10),

            const DCameraLogo(size: 75),

            const SizedBox(height: 12),

            const BrandName(),

            const SizedBox(height: 30),

            InputBox(
              controller: nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 16),

            InputBox(
              controller: emailController,
              label: 'Gmail',
              hint: 'example@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            InputBox(
              controller: mobileController,
              label: 'Mobile Number',
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),

            const SizedBox(height: 16),

            InputBox(
              controller: passwordController,
              label: 'Password',
              hint: 'Minimum 6 characters',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),

            const SizedBox(height: 16),

            InputBox(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.lock_reset_outlined,
              obscureText: obscureConfirmPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscureConfirmPassword = !obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),

            const SizedBox(height: 28),

            MainButton(
              text: 'CREATE ACCOUNT',
              icon: Icons.person_add_alt_1,
              onPressed: register,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  final String userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            DCameraLogo(size: 42),
            SizedBox(width: 10),
            Text(
              'DeepChildShield',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: navy,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlertsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName 👋',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Your child safety dashboard',
              style: TextStyle(
                fontSize: 15,
                color: textGrey,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    navy,
                    blue,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Protection Ready',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Monitoring',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 14),

            DashboardCard(
              icon: Icons.videocam_outlined,
              title: 'Live Monitoring',
              subtitle: 'View camera and safety status',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LiveMonitoringScreen(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.shield_outlined,
              title: 'Danger Zones',
              subtitle: 'Configure & manage hazard spots',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DangerZonesScreen(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.warning_amber_rounded,
              title: 'Alerts',
              subtitle: 'View recent safety alerts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AlertsScreen(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.history,
              title: 'History',
              subtitle: 'View previous monitoring events',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Manage system preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'PROTECT • PREVENT • CARE',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================
// ============================================================
// LIVE MONITORING
// ============================================================

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() =>
      _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  bool monitoring = false;
  bool connected = false;
  bool childDetected = false;
  bool adultDetected = false;
  bool isFetching = false;

  bool isSelectingRegion = false;
  Offset? dragStart;
  Offset? dragCurrent;
  List<dynamic> activeZones = [];

  bool childInDangerZone = false;
  String? currentDangerZoneName;
  bool isAlertPopupOpen = false;
  DateTime? lastAlertPopupTime;

  double? confidence;
  Uint8List? frameBytes;

  String alertMessage = 'Monitoring is stopped';
  String connectionMessage = 'Camera is not connected';

  Timer? pollingTimer;

  static Uri get frameUri => Uri.parse('$apiBaseUrl/api/camera/frame');

  @override
  void initState() {
    super.initState();
    fetchActiveZones();
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  void showDangerPopup(String zoneName, double? conf) {
    if (isAlertPopupOpen) return;
    final now = DateTime.now();
    if (lastAlertPopupTime != null && now.difference(lastAlertPopupTime!).inSeconds < 8) {
      return;
    }

    isAlertPopupOpen = true;
    lastAlertPopupTime = now;

    final confPct = conf != null ? (conf * 100).toStringAsFixed(1) : null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: dangerRed, width: 2),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: dangerRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CRITICAL DANGER ALERT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: dangerRed,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child entered danger zone: $zoneName!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Immediate parent action recommended. Check on your child to prevent injury or fall.',
                style: TextStyle(fontSize: 13, color: textGrey, height: 1.4),
              ),
              if (confPct != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI Detection Confidence: $confPct%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: navy),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                isAlertPopupOpen = false;
                Navigator.pop(dialogCtx);
              },
              child: const Text('ACKNOWLEDGE & DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      isAlertPopupOpen = false;
    });
  }

  Future<void> fetchActiveZones() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/danger-zones'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data is List) {
          setState(() {
            activeZones = data;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> saveRegionAsZone({
    required double leftPct,
    required double topPct,
    required double rightPct,
    required double bottomPct,
    required String name,
    required String severity,
  }) async {
    final points = [
      {'x': leftPct, 'y': topPct},
      {'x': rightPct, 'y': topPct},
      {'x': rightPct, 'y': bottomPct},
      {'x': leftPct, 'y': bottomPct},
    ];
    final color = severity == 'danger' ? '#ef4444' : '#f97316';

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/danger-zones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.isEmpty ? 'Selected Danger Spot' : name,
          'type': 'rectangle',
          'points': points,
          'severity': severity,
          'color': color,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: safeGreen,
            content: Text('Danger spot "$name" saved successfully!'),
          ),
        );
        fetchActiveZones();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: dangerRed,
          content: Text('Failed to save spot: $e'),
        ),
      );
    }
  }

  void promptSaveRegion(double boxWidth, double boxHeight) {
    if (dragStart == null || dragCurrent == null) return;

    final left = math.min(dragStart!.dx, dragCurrent!.dx).clamp(0.0, boxWidth);
    final top = math.min(dragStart!.dy, dragCurrent!.dy).clamp(0.0, boxHeight);
    final right = math.max(dragStart!.dx, dragCurrent!.dx).clamp(0.0, boxWidth);
    final bottom = math.max(dragStart!.dy, dragCurrent!.dy).clamp(0.0, boxHeight);

    final width = right - left;
    final height = bottom - top;

    if (width < 25 || height < 25) {
      setState(() {
        dragStart = null;
        dragCurrent = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please drag a larger box over the hazard area')),
      );
      return;
    }

    final leftPct = double.parse(((left / boxWidth) * 100).toStringAsFixed(1));
    final topPct = double.parse(((top / boxHeight) * 100).toStringAsFixed(1));
    final rightPct = double.parse(((right / boxWidth) * 100).toStringAsFixed(1));
    final bottomPct = double.parse(((bottom / boxHeight) * 100).toStringAsFixed(1));

    final nameController = TextEditingController(text: 'Window Danger Spot');
    String severity = 'danger';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.add_location_alt_outlined, color: dangerRed),
                  SizedBox(width: 8),
                  Text('Mark Danger Spot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Region: [${leftPct.toInt()}%, ${topPct.toInt()}%] to [${rightPct.toInt()}%, ${bottomPct.toInt()}%]',
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                    const SizedBox(height: 14),
                    const Text('Spot Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Window, Balcony Edge, Stairs',
                        filled: true,
                        fillColor: lightBlue,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Critical Danger'),
                          selected: severity == 'danger',
                          selectedColor: dangerRed.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: severity == 'danger' ? dangerRed : textGrey, fontWeight: FontWeight.bold),
                          onSelected: (_) => setDialogState(() => severity = 'danger'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Warning'),
                          selected: severity == 'warning',
                          selectedColor: Colors.orange.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: severity == 'warning' ? Colors.orange.shade800 : textGrey, fontWeight: FontWeight.bold),
                          onSelected: (_) => setDialogState(() => severity = 'warning'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      dragStart = null;
                      dragCurrent = null;
                    });
                  },
                  child: const Text('CANCEL / REDRAW'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      isSelectingRegion = false;
                      dragStart = null;
                      dragCurrent = null;
                    });
                    saveRegionAsZone(
                      leftPct: leftPct,
                      topPct: topPct,
                      rightPct: rightPct,
                      bottomPct: bottomPct,
                      name: nameController.text.trim(),
                      severity: severity,
                    );
                  },
                  child: const Text('CONFIRM & SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchFrame() async {
    if (isFetching || !monitoring) return;

    isFetching = true;

    try {
      final response = await http
          .get(frameUri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Flask returned HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid camera response');
      }

      final imageData = decoded['image'];
      if (imageData is! String) {
        throw Exception('Camera image is missing');
      }

      final detections = decoded['detections'] as List? ?? [];

      bool foundChild = false;
      bool foundAdult = false;
      double? childConfidence;

      for (final item in detections) {
        if (item is! Map) continue;

        final className =
            (item['class'] ?? '').toString().toLowerCase();

        final rawConfidence = item['confidence'];
        final detectedConfidence = rawConfidence is num
            ? rawConfidence.toDouble()
            : 0.0;

        if (className == 'child') {
          foundChild = true;
          if (childConfidence == null ||
              detectedConfidence > childConfidence) {
            childConfidence = detectedConfidence;
          }
        }

        if (className == 'adult') {
          foundAdult = true;
        }
      }

      final bool inDanger = decoded['childInDangerZone'] == true;
      final String? zoneName = decoded['dangerZoneName']?.toString();

      final imageBytes = base64Decode(imageData);

      if (!mounted || !monitoring) return;

      setState(() {
        connected = true;
        frameBytes = imageBytes;
        childDetected = foundChild;
        adultDetected = foundAdult;
        childInDangerZone = inDanger;
        currentDangerZoneName = zoneName;
        confidence = childConfidence;
        connectionMessage = 'Connected to Flask + YOLO';
        alertMessage = inDanger
            ? 'CRITICAL ALERT: Child in danger zone ($zoneName)!'
            : foundChild
                ? 'Child detected in secure area'
                : 'No child detected in current frame';
      });

      if (inDanger && zoneName != null) {
        showDangerPopup(zoneName, childConfidence);
        showSystemNotification(
          title: '🚨 DANGER ZONE ALERT: $zoneName!',
          body: 'Child detected entering hazard area! Check child immediately.',
        );
      }
    } catch (e) {
      if (!mounted || !monitoring) return;

      setState(() {
        connected = false;
        connectionMessage = 'Camera connection failed';
        alertMessage = 'Unable to receive camera frame';
      });
    } finally {
      isFetching = false;
    }
  }

  void toggleMonitoring() {
    if (monitoring) {
      pollingTimer?.cancel();

      setState(() {
        monitoring = false;
        connected = false;
        childDetected = false;
        adultDetected = false;
        confidence = null;
        frameBytes = null;
        alertMessage = 'Monitoring is stopped';
        connectionMessage = 'Camera is not connected';
      });
    } else {
      setState(() {
        monitoring = true;
        connectionMessage = 'Connecting to Flask + YOLO...';
        alertMessage = 'Starting camera monitoring';
      });

      fetchFrame();

      pollingTimer = Timer.periodic(
        const Duration(milliseconds: 1200),
        (_) => fetchFrame(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safetyLabel = !monitoring
        ? 'STOPPED'
        : !connected
            ? 'CONNECTING'
            : childInDangerZone
                ? 'CRITICAL: IN DANGER ZONE ($currentDangerZoneName)'
                : childDetected
                    ? 'CHILD DETECTED (SECURE)'
                    : 'MONITORING ACTIVE';

    return AppPage(
      title: 'Live Monitoring',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 340,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF17202B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxW = constraints.maxWidth;
                  final boxH = constraints.maxHeight;

                  double? selLeft;
                  double? selTop;
                  double? selWidth;
                  double? selHeight;

                  if (dragStart != null && dragCurrent != null) {
                    selLeft = math.min(dragStart!.dx, dragCurrent!.dx).clamp(0.0, boxW);
                    selTop = math.min(dragStart!.dy, dragCurrent!.dy).clamp(0.0, boxH);
                    final selRight = math.max(dragStart!.dx, dragCurrent!.dx).clamp(0.0, boxW);
                    final selBottom = math.max(dragStart!.dy, dragCurrent!.dy).clamp(0.0, boxH);
                    selWidth = selRight - selLeft;
                    selHeight = selBottom - selTop;
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: frameBytes != null
                            ? Image.memory(
                                frameBytes!,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) =>
                                    const Center(
                                  child: Text(
                                    'Unable to display camera frame',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.videocam_outlined,
                                      color: Colors.white70,
                                      size: 65,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Camera Feed',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      child: Text(
                                        connectionMessage,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // Existing configured danger zones overlay
                      for (final zone in activeZones)
                        if (zone is Map &&
                            zone['points'] is List &&
                            (zone['points'] as List).isNotEmpty)
                          Builder(
                            builder: (context) {
                              final pts = zone['points'] as List;
                              double minX = 100.0, minY = 100.0, maxX = 0.0, maxY = 0.0;
                              for (final p in pts) {
                                if (p is Map) {
                                  final px = (p['x'] as num?)?.toDouble() ?? 0.0;
                                  final py = (p['y'] as num?)?.toDouble() ?? 0.0;
                                  if (px < minX) minX = px;
                                  if (py < minY) minY = py;
                                  if (px > maxX) maxX = px;
                                  if (py > maxY) maxY = py;
                                }
                              }
                              if (maxX <= minX || maxY <= minY) {
                                return const SizedBox.shrink();
                              }

                              final zLeft = (minX / 100.0) * boxW;
                              final zTop = (minY / 100.0) * boxH;
                              final zW = ((maxX - minX) / 100.0) * boxW;
                              final zH = ((maxY - minY) / 100.0) * boxH;
                              final isCrit = (zone['severity'] ?? '') == 'danger';

                              return Positioned(
                                left: zLeft,
                                top: zTop,
                                width: zW,
                                height: zH,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isCrit ? dangerRed : Colors.orange,
                                      width: 2,
                                    ),
                                    color: (isCrit ? dangerRed : Colors.orange)
                                        .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.topLeft,
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCrit ? dangerRed : Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '[ZONE] ${zone['name'] ?? 'Danger Spot'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                      // User interactive drag selection box
                      if (selLeft != null &&
                          selTop != null &&
                          selWidth != null &&
                          selHeight != null)
                        Positioned(
                          left: selLeft,
                          top: selTop,
                          width: selWidth,
                          height: selHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.redAccent, width: 2.5),
                              color: Colors.red.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DANGER SPOT REGION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Transparent gesture detector for dragging danger spot
                      if (isSelectingRegion)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              setState(() {
                                dragStart = details.localPosition;
                                dragCurrent = details.localPosition;
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                dragCurrent = details.localPosition;
                              });
                            },
                            onPanEnd: (details) {
                              promptSaveRegion(boxW, boxH);
                            },
                          ),
                        ),

                      // Instruction banner when in region selection mode
                      if (isSelectingRegion)
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent, width: 1.5),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.touch_app,
                                    color: Colors.yellowAccent, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Drag your finger across camera to mark hazard spot',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (!isSelectingRegion)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: connected
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  !monitoring
                                      ? 'OFFLINE'
                                      : connected
                                          ? 'LIVE'
                                          : 'CONNECTING',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if ((childDetected || childInDangerZone) && !isSelectingRegion)
                        Positioned(
                          right: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: childInDangerZone ? dangerRed : Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  childInDangerZone
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  childInDangerZone
                                      ? 'DANGER: $currentDangerZoneName'
                                      : 'CHILD DETECTED',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: blue),
                      SizedBox(width: 10),
                      Text(
                        'AI Detection Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StatusRow(
                    label: 'Flask Backend',
                    value: connected ? 'CONNECTED' : 'DISCONNECTED',
                    active: connected,
                  ),
                  StatusRow(
                    label: 'Child Detection',
                    value: childDetected ? 'DETECTED' : 'NOT DETECTED',
                    active: childDetected,
                  ),
                  StatusRow(
                    label: 'Adult Detection',
                    value: adultDetected ? 'DETECTED' : 'NOT DETECTED',
                    active: adultDetected,
                  ),
                  StatusRow(
                    label: 'Monitoring Status',
                    value: safetyLabel,
                    active: monitoring && connected,
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 2),
                    StatusRow(
                      label: 'Child Confidence',
                      value:
                          '${(confidence! * 100).toStringAsFixed(1)}%',
                      active: childDetected,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      alertMessage,
                      style: TextStyle(
                        color: childDetected ? dangerRed : textGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            MainButton(
              text: monitoring ? 'STOP MONITORING' : 'START MONITORING',
              icon: monitoring
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              onPressed: toggleMonitoring,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelectingRegion ? Colors.grey.shade800 : dangerRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(isSelectingRegion
                  ? Icons.cancel_outlined
                  : Icons.crop_free_rounded),
              label: Text(
                isSelectingRegion
                    ? 'CANCEL REGION SELECTION'
                    : 'MARK DANGER REGION ON CAMERA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  isSelectingRegion = !isSelectingRegion;
                  dragStart = null;
                  dragCurrent = null;
                });
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: navy, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text(
                'VIEW & MANAGE DANGER SPOTS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DangerZonesScreen(),
                  ),
                ).then((_) => fetchActiveZones());
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Live camera frames and child/adult detections are received '
              'from the Flask backend using the trained YOLO model.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}



// ALERTS
// ============================================================

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/alerts'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted && data is List) {
          setState(() {
            alerts = data;
            loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Safety Alerts',
      onBack: () => Navigator.pop(context),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAlerts,
              child: alerts.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        AlertCard(
                          icon: Icons.check_circle_outline,
                          title: 'No Active Danger',
                          message: 'No child-in-danger-zone events recorded.',
                          time: 'All Secure',
                          safe: true,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final a = alerts[index];
                        final isDanger = a['status'] == 'danger';
                        final zoneName = a['danger_zone'] ?? 'Hazard Area';
                        final timeStr = '${a['date'] ?? ''} ${a['time'] ?? ''}';
                        final conf = ((a['confidence'] ?? 0.0) * 100).toInt();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDanger
                                  ? dangerRed.withValues(alpha: 0.4)
                                  : Colors.orange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDanger
                                  ? const Color(0xFFFFE5E5)
                                  : const Color(0xFFFFF3E0),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: isDanger ? dangerRed : Colors.orange,
                              ),
                            ),
                            title: Text(
                              'Child Entered: $zoneName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            subtitle: Text(
                              'Status: ${isDanger ? "CRITICAL ALERT" : "WARNING"} (Confidence: $conf%)\nTime: $timeStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDanger ? dangerRed : Colors.orange.shade800,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ============================================================
// HISTORY
// ============================================================

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'History',
      onBack: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 45,
                    color: navy,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Monitoring History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Detected events, snapshots and danger clips will be stored here for review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            HistoryItem(
              date: 'Today',
              title: 'System Ready',
              subtitle: 'Monitoring system initialized',
              icon: Icons.power_settings_new,
            ),

            HistoryItem(
              date: 'No recent events',
              title: 'No danger events recorded',
              subtitle: 'Event history will appear after monitoring',
              icon: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// DANGER ZONES SCREEN
// ============================================================

class DangerZonesScreen extends StatefulWidget {
  const DangerZonesScreen({super.key});

  @override
  State<DangerZonesScreen> createState() => _DangerZonesScreenState();
}

class _DangerZonesScreenState extends State<DangerZonesScreen> {
  static String get apiBase => apiBaseUrl;

  List<dynamic> zones = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchZones();
  }

  Future<void> fetchZones() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$apiBase/api/danger-zones'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;

        setState(() {
          zones = data is List ? data : [];
          loading = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> createZone({
    required String name,
    required String severity,
    required String presetArea,
  }) async {
    List<Map<String, double>> points;
    if (presetArea == 'Balcony / Window (Top)') {
      points = [
        {'x': 0.0, 'y': 0.0},
        {'x': 100.0, 'y': 0.0},
        {'x': 100.0, 'y': 45.0},
        {'x': 0.0, 'y': 45.0},
      ];
    } else if (presetArea == 'Stairs / Floor Edge (Bottom)') {
      points = [
        {'x': 0.0, 'y': 55.0},
        {'x': 100.0, 'y': 55.0},
        {'x': 100.0, 'y': 100.0},
        {'x': 0.0, 'y': 100.0},
      ];
    } else if (presetArea == 'Left Hazard Side') {
      points = [
        {'x': 0.0, 'y': 0.0},
        {'x': 45.0, 'y': 0.0},
        {'x': 45.0, 'y': 100.0},
        {'x': 0.0, 'y': 100.0},
      ];
    } else if (presetArea == 'Right Hazard Side') {
      points = [
        {'x': 55.0, 'y': 0.0},
        {'x': 100.0, 'y': 0.0},
        {'x': 100.0, 'y': 100.0},
        {'x': 55.0, 'y': 100.0},
      ];
    } else {
      points = [
        {'x': 20.0, 'y': 20.0},
        {'x': 80.0, 'y': 20.0},
        {'x': 80.0, 'y': 80.0},
        {'x': 20.0, 'y': 80.0},
      ];
    }

    final color = severity == 'danger' ? '#ef4444' : '#f97316';

    try {
      final response = await http.post(
        Uri.parse('$apiBase/api/danger-zones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.isEmpty ? 'Custom Danger Spot' : name,
          'type': 'rectangle',
          'points': points,
          'severity': severity,
          'color': color,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: safeGreen,
            content: Text('Danger spot "$name" configured successfully!'),
          ),
        );
        fetchZones();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: dangerRed,
          content: Text('Failed to save danger spot: $e'),
        ),
      );
    }
  }

  void showAddZoneDialog() {
    final nameController = TextEditingController(text: 'Balcony Edge');
    String selectedSeverity = 'danger';
    String selectedPreset = 'Balcony / Window (Top)';

    final presets = [
      'Balcony / Window (Top)',
      'Stairs / Floor Edge (Bottom)',
      'Left Hazard Side',
      'Right Hazard Side',
      'Center Hazard Area',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: dangerRed.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_location_alt_outlined,
                            color: dangerRed,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configure Danger Spot',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                'Define area where child fall risk is high',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hazard Spot Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Balcony, Window, Bed Edge, Stairs',
                        filled: true,
                        fillColor: lightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.edit_location_alt_outlined, color: blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Coverage Preset',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPreset,
                          isExpanded: true,
                          items: presets.map((p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(p, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedPreset = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Severity Level',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text(
                                'Critical Danger',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            selected: selectedSeverity == 'danger',
                            selectedColor: dangerRed.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedSeverity == 'danger' ? dangerRed : textGrey,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedSeverity = 'danger');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text(
                                'Caution Warning',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            selected: selectedSeverity == 'warning',
                            selectedColor: Colors.orange.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedSeverity == 'warning' ? Colors.orange.shade800 : textGrey,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedSeverity = 'warning');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    MainButton(
                      text: 'SAVE DANGER SPOT',
                      icon: Icons.check_circle_outline,
                      onPressed: () {
                        Navigator.pop(ctx);
                        createZone(
                          name: nameController.text.trim(),
                          severity: selectedSeverity,
                          presetArea: selectedPreset,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deleteZone(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$apiBase/api/danger-zones/$id'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Danger zone deleted successfully')),
        );
        fetchZones();
      } else {
        throw Exception('Could not delete zone');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Danger Zone?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteZone(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Danger Zones'),
        backgroundColor: const Color(0xFF123B6D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: showAddZoneDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Danger Spot',
          ),
          IconButton(
            onPressed: fetchZones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddZoneDialog,
        backgroundColor: const Color(0xFF123B6D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Add Danger Spot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 45, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('Unable to load danger zones'),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(error!, textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: fetchZones,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              : zones.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: lightBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 55,
                                color: blue,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No Danger Spots Configured',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mark hazardous areas (e.g. Balcony, Window, Stairs) to protect your child with real-time detection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: textGrey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: showAddZoneDialog,
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text(
                                'CONFIGURE DANGER SPOT',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchZones,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: zones.length,
                        itemBuilder: (context, index) {
                          final zone = zones[index];
                          final name = zone['name']?.toString() ?? 'Unnamed Zone';
                          final severity =
                              zone['severity']?.toString() ?? 'danger';
                          final type = zone['type']?.toString() ?? 'polygon';
                          final id = zone['id']?.toString() ?? '';

                          final isCritical = severity.toLowerCase() == 'danger';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isCritical
                                    ? dangerRed.withValues(alpha: 0.3)
                                    : Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCritical
                                    ? const Color(0xFFFFE5E5)
                                    : const Color(0xFFFFF3E0),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: isCritical ? Colors.red : Colors.orange,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              subtitle: Text(
                                'Coverage: $type • ${isCritical ? "CRITICAL DANGER" : "CAUTION WARNING"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCritical ? dangerRed : Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Delete zone',
                                onPressed: id.isEmpty
                                    ? null
                                    : () => confirmDelete(id, name),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Settings',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SettingSectionTitle(
            title: 'System',
          ),

          SettingTile(
            icon: Icons.videocam_outlined,
            title: 'Camera',
            subtitle: 'Configure monitoring camera',
            onTap: () {},
          ),

          SettingTile(
            icon: Icons.location_on_outlined,
            title: 'Danger Zones',
            subtitle: 'Manage protected areas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DangerZonesScreen(),
                ),
              );
            },
          ),

          SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Alert preferences',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          const SettingSectionTitle(
            title: 'Account',
          ),

          SettingTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Parent account',
            onTap: () {},
          ),

          const SizedBox(height: 25),

          MainButton(
            text: 'LOGOUT',
            icon: Icons.logout,
            danger: true,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_user_name');
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMMON APP PAGE
// ============================================================

class AppPage extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const AppPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            color: navy,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: child,
    );
  }
}

// ============================================================
// CUSTOM D + CAMERA LOGO
// ============================================================

class DCameraLogo extends StatelessWidget {
  final double size;

  const DCameraLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .82,
            height: size * .82,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(size * .22),
            ),
          ),

          Text(
            'D',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * .53,
              fontWeight: FontWeight.bold,
            ),
          ),

          Positioned(
            right: size * .10,
            bottom: size * .22,
            child: Container(
              width: size * .27,
              height: size * .27,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: blue,
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: size * .11,
                  height: size * .11,
                  decoration: const BoxDecoration(
                    color: blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BRAND
// ============================================================

class BrandName extends StatelessWidget {
  const BrandName({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'DeepChildShield',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: .2,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'PROTECT • PREVENT • CARE',
          style: TextStyle(
            color: blue,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// INPUT BOX
// ============================================================

class InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLength;

  const InputBox({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: navy,
        ),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: blue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAIN BUTTON
// ============================================================

class MainButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  const MainButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: .5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: danger ? dangerRed : navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD CARD
// ============================================================

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: navy,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: textGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATUS ROW
// ============================================================

class StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const StatusRow({
    super.key,
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: active ? safeGreen : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: active ? safeGreen : textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ALERT CARD
// ============================================================

class AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool safe;

  const AlertCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.safe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: safe
              ? Colors.green.shade100
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: safe ? safeGreen : blue,
            size: 29,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HISTORY ITEM
// ============================================================

class HistoryItem extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final IconData icon;

  const HistoryItem({
    super.key,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: navy,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingSectionTitle extends StatelessWidget {
  final String title;

  const SettingSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: navy,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: navy,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: textGrey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: textGrey,
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM TAGLINE
// ============================================================

class BottomTagline extends StatelessWidget {
  const BottomTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'SMART MONITORING FOR SAFER TOMORROWS',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textGrey,
        fontSize: 10,
        letterSpacing: .8,
      ),
    );
  }
}
