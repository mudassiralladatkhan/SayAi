import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/referral_service.dart';
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
  String _wakeWord = 'Hey YOG';
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _wakeWordController = TextEditingController(text: 'Hey YOG');
  bool _isApplyingCode = false;
  String? _referralMessage;

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
    await prefs.setString('wake_word', _wakeWord.isNotEmpty ? _wakeWord : 'Hey YOG');
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _currentPage == 0
            ? _buildWelcomePage()
            : _currentPage == 1
                ? _buildTonePage()
                : _currentPage == 2
                    ? _buildLanguagePage()
                    : _currentPage == 3
                        ? _buildWakeWordPage()
                        : _buildReferralPage(),
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
    return SingleChildScrollView(
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
    return SingleChildScrollView(
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
          _buildNextButton(() => setState(() => _currentPage = 3), label: "Next →"),
        ],
      ),
    );
  }

  Widget _buildWakeWordPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Wake Word 🎙️',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          const Text(
            'YOG will only respond when you say this word. Choose something easy to say!',
            style: TextStyle(fontSize: 16, color: AppTheme.textGray),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _wakeWordController,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Hey YOG',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: AppTheme.backgroundCardMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
              ),
              prefixIcon: const Icon(Icons.mic_rounded, color: AppTheme.primaryPurple),
            ),
            onChanged: (val) => _wakeWord = val.trim(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Suggestions:', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 8),
                Text('• Hey YOG', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                Text('• OK YOG', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                Text('• Sun YOG', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                Text('• Bol YOG', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildNextButton(() => setState(() => _currentPage = 4), label: "Next →"),
        ],
      ),
    );
  }

  Widget _buildReferralPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Referral Code 🎁',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          const Text(
            'Got a friend\'s code? Enter it for 3 bonus days!',
            style: TextStyle(fontSize: 16, color: AppTheme.textGray),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _referralController,
            style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 4),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ENTER CODE',
              hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 2),
              filled: true,
              fillColor: AppTheme.backgroundCardMedium,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_referralMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _referralMessage!.startsWith('SUCCESS')
                    ? AppTheme.success.withOpacity(0.15)
                    : AppTheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _referralMessage!.replaceFirst('SUCCESS: ', ''),
                style: TextStyle(
                  color: _referralMessage!.startsWith('SUCCESS') ? AppTheme.success : AppTheme.error,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isApplyingCode ? null : _applyReferralCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isApplyingCode
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Apply Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
          _buildNextButton(_completeOnboarding, label: "Skip"),
        ],
      ),
    );
  }

  Future<void> _applyReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) {
      setState(() => _referralMessage = 'Please enter a referral code.');
      return;
    }
    setState(() { _isApplyingCode = true; _referralMessage = null; });
    final result = await ReferralService.applyReferralCode(code);
    if (mounted) {
      setState(() {
        _isApplyingCode = false;
        _referralMessage = result;
      });
    }
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
