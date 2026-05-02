import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();

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
    required double amount, // In INR, not paise here, we multiply internally
    required String name,
    required String description,
    required String phone,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_YOUR_KEY', // Replace with your real key
      'amount': (amount * 100).toInt(), // amount in paise
      'name': name,
      'description': description,
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'theme': {
        'color': '#6C63FF'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: \$e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
