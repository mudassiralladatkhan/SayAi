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

  // Initialize notification service safely — don't crash if it fails
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Notification init failed (non-critical): $e');
  }

  // Get SharedPreferences — will be populated by Firestore if user is logged in
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

  final currentUser = FirebaseAuth.instance.currentUser;

  // If user is already logged in, restore their data from Firestore
  if (currentUser != null) {
    await UserService.loadProfileIntoPrefs();
  }

  // Check onboarding status (may have been updated by Firestore load above)
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
