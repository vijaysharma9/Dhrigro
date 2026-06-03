import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/payment_repository.dart';

final razorpayCheckoutServiceProvider = Provider<RazorpayCheckoutService>((ref) {
  return RazorpayCheckoutService(ref.read(paymentRepositoryProvider));
});

typedef RazorpaySuccessCallback = void Function({
  required String orderId,
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
});

typedef RazorpayFailureCallback = void Function(String message);

class RazorpayCheckoutService {
  RazorpayCheckoutService(this._repository);

  final PaymentRepository _repository;
  Razorpay? _razorpay;
  String? _pendingOrderId;
  RazorpaySuccessCallback? _onSuccess;
  RazorpayFailureCallback? _onFailure;

  bool get isSupported => !kIsWeb;

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  Future<void> startCheckout({
    required String orderId,
    required RazorpaySuccessCallback onSuccess,
    required RazorpayFailureCallback onFailure,
  }) async {
    if (kIsWeb) {
      onFailure(
        'Online payment is available on Android/iOS app. Please use COD on web.',
      );
      return;
    }

    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _pendingOrderId = orderId;

    final checkoutData = await _repository.createRazorpayOrder(orderId);
    final keyId = checkoutData['keyId'] as String? ?? '';
    final razorpayOrderId = checkoutData['razorpayOrderId'] as String? ?? '';
    final amount = checkoutData['amount'] as int? ?? 0;
    final prefill = checkoutData['prefill'] as Map<String, dynamic>? ?? {};

    if (keyId.isEmpty || razorpayOrderId.isEmpty) {
      onFailure('Payment gateway not configured');
      return;
    }

    _razorpay?.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = {
      'key': keyId,
      'amount': amount,
      'currency': checkoutData['currency'] ?? 'INR',
      'name': 'Daily Rashan',
      'description': 'Order ${checkoutData['orderNumber'] ?? ''}',
      'order_id': razorpayOrderId,
      'prefill': {
        'contact': prefill['contact'] ?? '',
        'email': prefill['email'] ?? '',
        'name': prefill['name'] ?? '',
      },
      'theme': {'color': '#1FA54A'},
    };

    _razorpay!.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final orderId = _pendingOrderId;
    if (orderId == null) return;

    _onSuccess?.call(
      orderId: orderId,
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final orderId = _pendingOrderId;
    final message =
        response.message ?? response.error?.description ?? 'Payment failed';

    if (orderId != null) {
      _repository.reportPaymentFailed(orderId, reason: message).catchError((_) {});
    }

    _onFailure?.call(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onFailure?.call('External wallet: ${response.walletName}');
  }
}
