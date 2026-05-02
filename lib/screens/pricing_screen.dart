import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'addon_screen.dart';
import 'referral_screen.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: const Text('SayNote AI Plans'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
              btnLabel: 'Premium Lo Abhi ✨',
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
              btnLabel: 'PRO SHURU KARO',
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
              btnLabel: 'CURRENT PLAN',
              isFree: true,
            ),
            const SizedBox(height: 32),

            // Add-on Packs Section
            const Align(alignment: Alignment.centerLeft, child: Text('Add-on Packs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customize karo apna plan', style: TextStyle(color: AppTheme.textWhite)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('STT: ₹1/min', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('TTS: ₹0.50/min', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                      Text('Tokens: ₹1/1500', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddonScreen())),
                    child: const Text('CUSTOM PACK BANAO'),
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
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.gold]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(btnLabel, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16))),
                  )
                else if (isPro)
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryPurple)),
                    child: Text(btnLabel, style: const TextStyle(color: AppTheme.primaryPurple)),
                  )
                else
                  OutlinedButton(
                    onPressed: () {},
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
