import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedTone = 'yaar';
  String _selectedLanguage = 'Hinglish';
  int _currentPage = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    // Delay so Navigator is fully ready before showing dialog
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _currentPage == 0) _showNameDialog();
    });
  }

  void _showNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundCardMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'What should YOG call you? 👋',
          style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 18),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Rahul',
            hintStyle: TextStyle(color: AppTheme.textGray.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.backgroundMain,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onSubmitted: (_) => _submitName(ctx, controller),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _submitName(ctx, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text('Next →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitName(BuildContext ctx, TextEditingController controller) {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    setState(() {
      _userName = controller.text.trim();
      _currentPage = 1;
    });
    Navigator.of(ctx).pop();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setString('yog_tone', _selectedTone);
    await prefs.setString('yog_language', _selectedLanguage);
    await prefs.setBool('has_onboarded', true);

    // Navigate immediately — don't block on Firestore
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );

    // Save to Firestore in background (non-blocking)
    UserService.saveProfile(
      name: _userName,
      tone: _selectedTone,
      language: _selectedLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: _currentPage == 0
            ? _buildWelcomePage()
            : _currentPage == 1
                ? _buildTonePage()
                : _buildLanguagePage(),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Welcome to', style: TextStyle(color: AppTheme.textGray, fontSize: 20)),
          const SizedBox(height: 8),
          const Text(
            'SayNote AI 👋',
            style: TextStyle(color: AppTheme.textWhite, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _showNameDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            ),
            child: const Text(
              'Get Started →',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTonePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Hey $_userName! 🤖',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pick YOG's personality:",
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            'Chill Yaar 🤙',
            'Casual & friendly like a bro.',
            _selectedTone == 'yaar',
            () => setState(() => _selectedTone = 'yaar'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            'Strict Coach 😤',
            'Pushes you hard, no excuses.',
            _selectedTone == 'coach',
            () => setState(() => _selectedTone = 'coach'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            'Funny Bestie 😂',
            'Lots of jokes and teasing.',
            _selectedTone == 'friend',
            () => setState(() => _selectedTone = 'friend'),
          ),
          const SizedBox(height: 32),
          _buildNextButton(() => setState(() => _currentPage = 2)),
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Language 🗣️',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          const Text(
            'Which language do you prefer?',
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            'Hinglish (Recommended)',
            'Perfect mix of Hindi and English.',
            _selectedLanguage == 'Hinglish',
            () => setState(() => _selectedLanguage = 'Hinglish'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            'English Only',
            'Strictly English responses.',
            _selectedLanguage == 'English',
            () => setState(() => _selectedLanguage = 'English'),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            'Pure Hindi (हिंदी)',
            'Devanagari script only.',
            _selectedLanguage == 'Hindi',
            () => setState(() => _selectedLanguage = 'Hindi'),
          ),
          const SizedBox(height: 32),
          _buildNextButton(_completeOnboarding, label: "Let's Go! 🚀"),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : AppTheme.backgroundCardMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.white10,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textWhite, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onTap, {String label = 'Next →'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
