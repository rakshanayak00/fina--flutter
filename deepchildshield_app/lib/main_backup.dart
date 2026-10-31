import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DeepChildShieldApp());
}

// ============================================================
// APP
// ============================================================

class DeepChildShieldApp extends StatelessWidget {
  const DeepChildShieldApp({super.key});

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
      home: const LoginScreen(),
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

// ============================================================
// TEMPORARY LOCAL ACCOUNT STORAGE
// ============================================================

String? registeredName;
String? registeredEmail;
String? registeredMobile;
String? registeredPassword;

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

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (registeredEmail == null) {
      showMessage('Please register an account first.');
      return;
    }

    if (email != registeredEmail || password != registeredPassword) {
      showMessage('Incorrect email or password.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: registeredName ?? 'Parent'),
      ),
    );
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

  void register() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final gmailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    );

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

    registeredName = name;
    registeredEmail = email;
    registeredMobile = mobile;
    registeredPassword = password;

    showMessage('Registration successful.');

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
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
  double? confidence;
  String alertMessage = 'Monitoring is stopped';
  String connectionMessage = 'Not connected to Node-RED';
  Timer? pollingTimer;

  // For Flutter running on the same Mac as Node-RED.
  // For a physical phone, replace 127.0.0.1 with your Mac's local Wi-Fi IP.
  static final Uri statusUri =
      Uri.parse('http://' + '127.0.0.1:1880/deepchildshield/status');

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStatus() async {
    try {
      final response = await http
          .get(statusUri)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (!mounted) return;
          setState(() {
            connected = decoded['connected'] == true;
            childDetected = decoded['childDetected'] == true;
            adultDetected = decoded['adultDetected'] == true;
            final rawConfidence = decoded['confidence'];
            confidence = rawConfidence is num ? rawConfidence.toDouble() : null;
            alertMessage = (decoded['alert'] ?? 'No alert information').toString();
            connectionMessage = connected
                ? 'Connected to Node-RED'
                : 'Node-RED responded, but status is not connected';
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          connected = false;
          connectionMessage = 'Node-RED returned HTTP ${response.statusCode}';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        connected = false;
        connectionMessage = 'Cannot reach Node-RED. Check that it is running.';
      });
    }
  }

  void toggleMonitoring() {
    if (monitoring) {
      pollingTimer?.cancel();
      setState(() {
        monitoring = false;
        alertMessage = 'Monitoring is stopped';
      });
    } else {
      setState(() {
        monitoring = true;
        connectionMessage = 'Connecting to Node-RED...';
      });
      fetchStatus();
      pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => fetchStatus(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safetyActive = monitoring && connected;
    final safetyLabel = !monitoring
        ? 'STOPPED'
        : !connected
            ? 'DISCONNECTED'
            : childDetected
                ? 'CHILD DETECTED'
                : 'NO CHILD DETECTED';

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
              decoration: BoxDecoration(
                color: const Color(0xFF17202B),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Center(
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
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            'Camera video is not connected yet\n$connectionMessage',
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
                              color: safetyActive
                                  ? Colors.greenAccent
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            monitoring ? (connected ? 'LIVE' : 'CONNECTING') : 'OFFLINE',
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
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: dangerRed.withOpacity(.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
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
                    label: 'Node-RED Connection',
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
                    label: 'Safety Status',
                    value: safetyLabel,
                    active: safetyActive && !childDetected,
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 2),
                    StatusRow(
                      label: 'Child Confidence',
                      value: '${(confidence! * 100).toStringAsFixed(1)}%',
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
            const SizedBox(height: 14),
            const Text(
              'YOLO-based child/adult detection status from Node-RED. The camera video feed is a separate connection and is not displayed yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ALERTS
// ============================================================

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Alerts',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          AlertCard(
            icon: Icons.check_circle_outline,
            title: 'No Active Danger',
            message: 'No current child-in-danger-zone event.',
            time: 'Current Status',
            safe: true,
          ),
          SizedBox(height: 14),
          AlertCard(
            icon: Icons.notifications_none,
            title: 'Alert History',
            message:
                'Safety events detected by the monitoring system will appear here.',
            time: 'History',
            safe: false,
          ),
        ],
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
            onTap: () {},
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
            subtitle: registeredName ?? 'Parent account',
            onTap: () {},
          ),

          const SizedBox(height: 25),

          MainButton(
            text: 'LOGOUT',
            icon: Icons.logout,
            danger: true,
            onPressed: () {
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
