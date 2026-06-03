/// Future-ready client location layer (live tracking disabled).
abstract class DeliveryLocationService {
  bool get isLiveTrackingEnabled => false;

  Future<void> reportPosition({
    required double latitude,
    required double longitude,
  });
}

class NoopDeliveryLocationService implements DeliveryLocationService {
  @override
  Future<void> reportPosition({
    required double latitude,
    required double longitude,
  }) async {
    // Wire to PATCH /delivery/location when GPS tracking is enabled.
  }
}
