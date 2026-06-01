import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/task_provider.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (using google-services.json defaults)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Get SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  };

  User? currentUser;
  try {
    currentUser = FirebaseAuth.instance.currentUser;
  } catch (e) {
    debugPrint('Auth initialization failed: $e');
  }
  final bool hasOnboarded = prefs.getBool('has_onboarded') ?? false;

  Widget initialScreen;
  if (currentUser == null) {
    initialScreen = const AuthScreen();
  } else if (!hasOnboarded) {
    initialScreen = const OnboardingScreen();
  } else {
    initialScreen = const HomeScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()..loadTasks()),
      ],
      child: SayNoteApp(initialScreen: initialScreen),
    ),
  );

  // Deferred non-blocking init after UI is shown
  if (currentUser != null) {
    UserService.loadProfileIntoPrefs();
    UserService.checkAndUpdateStreak();
  }
  try {
    final notificationService = NotificationService();
    notificationService.initialize();
    notificationService.requestPermissions();
  } catch (_) {}
}

class SayNoteApp extends StatelessWidget {
  final Widget initialScreen;
  const SayNoteApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SayNote AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialScreen,
    );
  }
}
