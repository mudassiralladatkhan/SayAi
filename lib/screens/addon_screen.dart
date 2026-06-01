import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/yog_avatar.dart';
import '../services/payment_service.dart';

class AddonScreen extends StatefulWidget {
  const AddonScreen({Key? key}) : super(key: key);

  @override
  State<AddonScreen> createState() => _AddonScreenState();
}

class _AddonScreenState extends State<AddonScreen> {
  double sttMinutes = 0;
  double ttsMinutes = 0;
  double tokens = 0;
  final PaymentService _paymentService = PaymentService();

  double get sttPrice => sttMinutes * 1.0;
  double get ttsPrice => ttsMinutes * 0.5;
  double get tokenPrice => (tokens / 1500) * 1.0;
  double get totalPrice => sttPrice + ttsPrice + tokenPrice;

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onPaymentSuccess: (paymentId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Add-on pack purchased! 🎉'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      onPaymentError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $message'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _purchaseAddon() {
    final amountInPaise = (totalPrice * 100).toInt();
    _paymentService.openCheckout(
      planName: 'Add-on Pack',
      amountInPaise: amountInPaise,
      userName: 'User',
      email: 'user@saynoteai.com',
      phone: '9999999999',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isValid = totalPrice >= 19.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        title: const Text('Custom Add-ons'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Sirfwahi lo jo chahiye', style: TextStyle(color: AppTheme.textGray, fontSize: 14)),
            const SizedBox(height: 24),

            // YOG Message Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  YogAvatar.small(),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'YOG kehta hai: Choose karo kya chahiye — STT, TTS ya Tokens. Minimum ₹19 ka pack banao!',
                      style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // STT Slider
            _buildSliderSection(
              '🎤 Voice Input STT',
              'Whisper STT Minutes',
              sttMinutes,
              60,
              (v) => setState(() => sttMinutes = v),
              '${sttMinutes.toInt()} min × ₹1 = ₹${sttPrice.toStringAsFixed(2)}',
              'Better accuracy for Hinglish',
            ),
            const SizedBox(height: 24),

            // TTS Slider
            _buildSliderSection(
              '🔊 Voice Output TTS',
              'TTS Minutes',
              ttsMinutes,
              120,
              (v) => setState(() => ttsMinutes = v),
              '${ttsMinutes.toInt()} min × ₹0.50 = ₹${ttsPrice.toStringAsFixed(2)}',
              'YOG ki awaaz ke liye',
            ),
            const SizedBox(height: 24),

            // Tokens Slider
            _buildSliderSection(
              '🧠 AI Tokens',
              'Tokens',
              tokens,
              10000,
              (v) => setState(() => tokens = (v ~/ 500) * 500.0),
              '${tokens.toInt()} tokens × ₹1/1500 = ₹${tokenPrice.toStringAsFixed(2)}',
              'Zyada baat karo YOG se',
              divisions: 20,
            ),
            const SizedBox(height: 32),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  const SizedBox(height: 16),
                  _buildSummaryRow('STT (${sttMinutes.toInt()} min)', '₹${sttPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('TTS (${ttsMinutes.toInt()} min)', '₹${ttsPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Tokens (${tokens.toInt()})', '₹${tokenPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                      Text('₹${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isValid ? AppTheme.success.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        isValid ? '✅ Minimum ₹19 — valid hai!' : '⚠️ ₹19 se zyada karo',
                        style: TextStyle(color: isValid ? AppTheme.success : AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _InfoBadge('📅 30 days validity'),
                _InfoBadge('⚠️ Base plan required'),
                _InfoBadge('🔄 No auto-renewal'),
              ],
            ),
            const SizedBox(height: 32),

            // Purchase Button
            ElevatedButton(
              onPressed: isValid ? _purchaseAddon : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? AppTheme.primaryPurple : const Color(0xFF2A2A2A),
              ),
              child: Text('₹${totalPrice.toStringAsFixed(2)} ka Pack Kharido →'),
            ),
            const SizedBox(height: 16),
            const Text('🔒 Secure payment via Razorpay', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(String title, String label, double value, double max, Function(double) onChanged, String calc, String info, {int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textWhite, fontSize: 14)),
            Text(value.toInt().toString(), style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          max: max,
          divisions: divisions ?? max.toInt(),
          activeColor: AppTheme.primaryPurple,
          onChanged: onChanged,
        ),
        Text(calc, style: const TextStyle(color: AppTheme.textWhite, fontSize: 14)),
        const SizedBox(height: 4),
        Text(info, style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppTheme.textWhite, fontSize: 14)),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;
  const _InfoBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: AppTheme.textGray, fontSize: 10)),
    );
  }
}
