import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../services/payment_service.dart';
import 'addon_screen.dart';
import 'referral_screen.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  int _currentIndex = 3;
  final PaymentService _paymentService = PaymentService();
  String _userName = 'User';
  String _currentPlan = 'free';

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: _onPaymentError,
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _currentPlan = prefs.getString('current_plan') ?? 'free';
    });
  }

  void _onPaymentSuccess(String paymentId) {
    _loadUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment successful! Welcome to Premium! 🎉'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onPaymentError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $message'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startPayment(String planName, int amountInPaise) {
    _paymentService.openCheckout(
      planName: planName,
      amountInPaise: amountInPaise,
      userName: _userName,
      email: 'user@saynoteai.com',
      phone: '9999999999',
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('SayNote AI Plans', style: TextStyle(color: AppTheme.textWhite, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('YOG ke saath apni zindagi badlo 🚀', style: TextStyle(color: AppTheme.textGray, fontSize: 14)),
                    const SizedBox(height: 24),
                    const Text('15 din free trial — card nahi chahiye', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                    const SizedBox(height: 24),

            // Premium Plan (Most prominent)
            _buildPlanCard(
              context: context,
              title: 'Premium',
              price: '₹299',
              isPremium: true,
              badge: 'BEST VALUE',
              features: [
                'Everything in Pro',
                '60 messages/day',
                'TTS 220 min/month',
                'Whisper STT fallback 3 min/day',
                '14 unique alarm scripts + jokes',
                'Smart snooze with YOG reaction',
                'All 4 YOG tone modes',
                'Unlimited Voice Diary',
                'Full Firebase history',
                'Monthly YOG Letter 💌',
                'Early V2 access',
                'Priority support',
              ],
              btnLabel: _currentPlan == 'premium' ? 'CURRENT PLAN ✅' : 'Premium Lo Abhi ✨',
              onTap: _currentPlan == 'premium' ? null : () => _startPayment('Premium', 29900),
            ),
            const SizedBox(height: 24),

            // Pro Plan
            _buildPlanCard(
              context: context,
              title: 'Pro',
              price: '₹149',
              isPremium: false,
              isPro: true,
              badge: '⚡ POPULAR',
              features: [
                'Everything in Free',
                '20 messages/day',
                'TTS 120 min/month',
                'YOG voice alarm 3 scripts',
                'Voice Diary 10 min/day',
                'Firebase sync 30 days',
                'Referral rewards',
              ],
              btnLabel: _currentPlan == 'pro' ? 'CURRENT PLAN ✅' : 'PRO SHURU KARO',
              onTap: _currentPlan == 'pro' ? null : () => _startPayment('Pro', 14900),
            ),
            const SizedBox(height: 24),

            // Free Plan
            _buildPlanCard(
              context: context,
              title: 'Free',
              price: '₹0',
              isPremium: false,
              features: [
                'Basic YOG companion',
                '3 tasks per day',
                'Morning alarm basic',
                'Local history 7 days',
                'Voice diary (No)',
                'Premium alarm scripts (No)',
              ],
              btnLabel: _currentPlan == 'free' ? 'CURRENT PLAN' : 'FREE PLAN',
              isFree: true,
            ),
            const SizedBox(height: 32),

            // Add-on Packs Section
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryPurple, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.extension_rounded, color: AppTheme.primaryPurple, size: 22),
                      const SizedBox(width: 10),
                      const Text('Add-on Packs', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('CUSTOM', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Customize karo apna plan — sirf wahi lo jo chahiye!', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('STT: ₹1/min', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('TTS: ₹0.50/min', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('Tokens: ₹1/1500', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddonScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CUSTOM PACK BANAO →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Referral Banner
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF2D1B69)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Expanded(child: Text('🎁 Dosto ko refer karo — 7 din free Pro pao!', style: TextStyle(color: AppTheme.textWhite, fontSize: 14))),
                    Icon(Icons.chevron_right, color: AppTheme.textWhite),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required bool isPremium,
    bool isPro = false,
    bool isFree = false,
    String? badge,
    required List<String> features,
    required String btnLabel,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: isPremium ? Border.all(color: AppTheme.gold, width: 2) : (isPro ? Border.all(color: AppTheme.primaryPurple, width: 1) : null),
        boxShadow: isPremium ? [BoxShadow(color: AppTheme.gold.withOpacity(0.2), blurRadius: 20)] : null,
      ),
      child: Column(
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isPremium ? AppTheme.gold : const Color(0xFF4A90D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge, style: TextStyle(color: isPremium ? Colors.black : AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (isPremium) const Text('👑', style: TextStyle(fontSize: 40)),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isPremium ? AppTheme.gold : AppTheme.textWhite)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isPremium ? AppTheme.gold : AppTheme.textWhite)),
                    const Text('/month', style: TextStyle(fontSize: 14, color: AppTheme.textGray)),
                  ],
                ),
                if (isPremium) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Save 40% vs competitors', style: TextStyle(color: AppTheme.success, fontSize: 12))),
                const SizedBox(height: 24),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.contains('(No)') ? '❌' : '✅', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f.replaceAll('(No)', ''), style: TextStyle(color: f.contains('(No)') ? AppTheme.textGray : AppTheme.textWhite, decoration: f.contains('(No)') ? TextDecoration.lineThrough : null))),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 24),
                if (isPremium)
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.gold]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(btnLabel, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  )
                else if (isPro)
                  OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryPurple)),
                    child: Text(btnLabel, style: const TextStyle(color: AppTheme.primaryPurple)),
                  )
                else
                  OutlinedButton(
                    onPressed: onTap,
                    child: Text(btnLabel, style: const TextStyle(color: AppTheme.textGray)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
