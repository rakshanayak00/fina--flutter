import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DeepChildShieldApp());
}

// ===================================
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


  static const String apiBase = 'http://127.0.0.1:5001';

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
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: user['name'] ?? 'Parent',
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
        Uri.parse('http://127.0.0.1:5001/api/auth/register'),
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

  double? confidence;
  Uint8List? frameBytes;

  String alertMessage = 'Monitoring is stopped';
  String connectionMessage = 'Camera is not connected';

  Timer? pollingTimer;

  static final Uri frameUri =
      Uri.parse('http://127.0.0.1:5001/api/camera/frame');

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
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

      final imageBytes = base64Decode(imageData);

      if (!mounted || !monitoring) return;

      setState(() {
        connected = true;
        frameBytes = imageBytes;
        childDetected = foundChild;
        adultDetected = foundAdult;
        confidence = childConfidence;
        connectionMessage = 'Connected to Flask + YOLO';
        alertMessage = foundChild
            ? 'Child detected by YOLO'
            : 'No child detected in the current frame';
      });
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
            : childDetected
                ? 'CHILD DETECTED'
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
              child: Stack(
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
                  if (childDetected)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dangerRed.withOpacity(.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CHILD DETECTED',
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
// DANGER ZONES SCREEN
// ============================================================

class DangerZonesScreen extends StatefulWidget {
  const DangerZonesScreen({super.key});

  @override
  State<DangerZonesScreen> createState() => _DangerZonesScreenState();
}

class _DangerZonesScreenState extends State<DangerZonesScreen> {
  static const String apiBase = 'http://127.0.0.1:5001';

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
            onPressed: fetchZones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
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
                  ? const Center(
                      child: Text('No danger zones configured yet.'),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchZones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: zones.length,
                        itemBuilder: (context, index) {
                          final zone = zones[index];
                          final name = zone['name']?.toString() ?? 'Unnamed Zone';
                          final severity =
                              zone['severity']?.toString() ?? 'danger';
                          final type = zone['type']?.toString() ?? 'polygon';
                          final id = zone['id']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFE5E5),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Type: $type\nSeverity: $severity',
                              ),
                              isThreeLine: true,
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
