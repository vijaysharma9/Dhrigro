import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/upload_repository.dart';

class UploadState {
  const UploadState({
    this.isUploading = false,
    this.progress = 0,
    this.error,
  });

  final bool isUploading;
  final double progress;
  final String? error;

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

final uploadStateProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.read(uploadRepositoryProvider));
});

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier(this._repository) : super(const UploadState());

  final UploadRepository _repository;

  Future<List<Map<String, dynamic>>> uploadProductImages({
    required List<UploadFilePayload> files,
    String? productId,
  }) async {
    state = const UploadState(isUploading: true, progress: 0);
    try {
      final result = await _repository.uploadProductImages(
        files: files,
        productId: productId,
        onProgress: (sent, total) {
          state = UploadState(
            isUploading: true,
            progress: total > 0 ? sent / total : 0,
          );
        },
      );
      state = const UploadState(isUploading: false, progress: 1);
      final images = (result['images'] as List?) ?? [];
      return images.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      state = UploadState(isUploading: false, error: e.toString());
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> uploadBannerImages(
    List<UploadFilePayload> files,
  ) async {
    state = const UploadState(isUploading: true, progress: 0);
    try {
      final result = await _repository.uploadBannerImages(
        files: files,
        onProgress: (sent, total) {
          state = UploadState(
            isUploading: true,
            progress: total > 0 ? sent / total : 0,
          );
        },
      );
      state = const UploadState(isUploading: false, progress: 1);
      final images = (result['images'] as List?) ?? [];
      return images.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      state = UploadState(isUploading: false, error: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = const UploadState();
  }
}
