import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Navigate after successful auth ───────────────────────────────────────
  Future<void> _afterAuth() async {
    await UserService.loadProfileIntoPrefs();
    await UserService.checkAndUpdateStreak();
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasOnboarded ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  // ─── Email / Password ──────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      await _afterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _afterAuth();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.mic_rounded, size: 44, color: AppTheme.primaryPurple),
                ),
                const SizedBox(height: 24),

                Text(
                  _isLogin ? 'Welcome Back!' : 'Join SayNote AI',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Log in to sync your tasks and diary.'
                      : 'Sign up to back up your data securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGray, fontSize: 15),
                ),
                const SizedBox(height: 32),

                // Google Sign-In Button
                OutlinedButton(
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppTheme.backgroundCardMedium,
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G logo using text (no asset needed)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: Colors.white12)),
                  ],
                ),
                const SizedBox(height: 20),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.backgroundCardMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 14),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.backgroundCardMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // Email Login / Sign Up Button
                ElevatedButton(
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isLogin ? 'Log In' : 'Sign Up',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Toggle Login / Sign Up
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Log In',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
