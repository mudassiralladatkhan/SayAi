import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();

  // Load key from .env — replace rzp_test_YOUR_KEY in .env with your real key
  String get _key => dotenv.env['RAZORPAY_KEY'] ?? 'rzp_test_YOUR_KEY';

  void initialize(
    Function(PaymentSuccessResponse) handlePaymentSuccess,
    Function(PaymentFailureResponse) handlePaymentError,
    Function(ExternalWalletResponse) handleExternalWallet,
  ) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String name,
    required String description,
    required String phone,
    required String email,
  }) {
    var options = {
      'key': _key,
      'amount': (amount * 100).toInt(), // in paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'theme': {'color': '#6C63FF'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Razorpay Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
