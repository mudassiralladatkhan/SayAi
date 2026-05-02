import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/referral_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String _myCode = '';
  String get _referralLink =>
      'https://saynoteai.carrd.co/?ref=$_myCode';
  String get _shareMessage =>
      '🎉 SayNote AI - Apna AI life assistant try karo!\n\nMain isko use kar raha hoon aur yeh kamal ka hai. '
      'Isse download karo aur mera referral code **$_myCode** enter karo — tujhe 3 bonus days milenge FREE! 🎁\n\n'
      'Download link: $_referralLink';

  int _referralCount = 0;
  int _rewardDays = 0;
  bool _isLoading = true;
  bool _wasReferred = false;
  String? _errorMessage;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final code = await ReferralService.getOrCreateCode()
          .timeout(const Duration(seconds: 8));
      final count = await ReferralService.getReferralCount()
          .timeout(const Duration(seconds: 8));
      final days = await ReferralService.getRewardDays()
          .timeout(const Duration(seconds: 8));
      final referred = await ReferralService.wasReferred()
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        setState(() {
          _myCode = code.isNotEmpty ? code : '------';
          _referralCount = count;
          _rewardDays = days;
          _wasReferred = referred;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _myCode = '------';
          _errorMessage = 'Could not load referral data. Check your connection.';
        });
      }
    }
  }

  void _copyCode() {
    if (_myCode == '------') return;
    Clipboard.setData(ClipboardData(text: _myCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $_myCode copied!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyLink() {
    if (_myCode == '------') return;
    Clipboard.setData(ClipboardData(text: _referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral link copied! 🔗'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareLink() {
    if (_myCode == '------') return;
    Share.share(
      _shareMessage,
      subject: 'SayNote AI - Try karo yaar! 🚀',
    );
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      ),
    );

    final result = await ReferralService.applyReferralCode(code);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: result.startsWith('SUCCESS') ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (result.startsWith('SUCCESS')) {
      _codeController.clear();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.backgroundMain,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryPurple),
                  SizedBox(height: 16),
                  Text('Loading your referral info...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: AppTheme.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                          GestureDetector(
                            onTap: _loadData,
                            child: const Text('Retry', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Banner Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, Color(0xFF2D1B69)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎁 Get 7 Days Free Pro!',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share your code. Friends get 3 bonus days — you get 7 free Pro days!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        // Referral Code Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _myCode,
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _copyCode,
                                child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 22),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap the icon to copy your code',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        // Referral Link
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'saynoteai.carrd.co/?ref=$_myCode',
                            style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Share / Copy buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionBtn(Icons.share_rounded, 'Share', AppTheme.primaryPurple, _shareLink),
                            const SizedBox(width: 10),
                            _buildActionBtn(Icons.link_rounded, 'Copy Link', Colors.blue, _copyLink),
                            const SizedBox(width: 10),
                            _buildActionBtn(Icons.copy_rounded, 'Copy Code', Colors.orange, _copyCode),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Friends Referred',
                          value: _referralCount.toString(),
                          icon: Icons.people_alt_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Free Days Earned',
                          value: '$_rewardDays days',
                          icon: Icons.card_giftcard_rounded,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // How it works
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How it works',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildStep('1', 'Share your code with a friend'),
                        _buildStep('2', 'They sign up and enter your code'),
                        _buildStep('3', 'They get 3 bonus days — you get 7 free Pro days! 🎉'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Apply Code Section
                  if (!_wasReferred) ...[
                    const Text('Have a friend\'s code?',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Enter Code',
                            hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 2),
                            filled: true,
                            fillColor: const Color(0xFF1A1A2E),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _applyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Apply Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.success),
                          SizedBox(width: 12),
                          Text('Aapne referral code use kar liya hai! ✅',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primaryPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }
}
