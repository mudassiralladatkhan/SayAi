import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';

class PaymentService {
  static const String _razorpayKey = 'rzp_test_SugdivTLjA9xJY';

  late Razorpay _razorpay;
  Function(String)? onSuccess;
  Function(String)? onError;

  void init({Function(String)? onPaymentSuccess, Function(String)? onPaymentError}) {
    _razorpay = Razorpay();
    onSuccess = onPaymentSuccess;
    onError = onPaymentError;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required String planName,
    required int amountInPaise,
    required String userName,
    required String email,
    required String phone,
  }) {
    final options = {
      'key': _razorpayKey,
      'amount': amountInPaise,
      'name': 'SayNote AI',
      'description': '$planName Plan - Monthly',
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'theme': {
        'color': '#7C3AED',
      },
      'notes': {
        'plan': planName,
      },
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    await prefs.setString('payment_id', response.paymentId ?? '');
    await prefs.setString('current_plan', 'premium');
    await prefs.setString('plan_start_date', DateTime.now().toIso8601String());

    UserService.savePlanInfo(
      plan: 'premium',
      paymentId: response.paymentId ?? '',
    );

    onSuccess?.call(response.paymentId ?? 'success');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onError?.call('External wallet: ${response.walletName}');
  }
}
