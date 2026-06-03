import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import '../../../core/network/dio_client.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioProvider));
});

class UploadFilePayload {
  const UploadFilePayload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

class UploadRepository {
  UploadRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> uploadProductImages({
    required List<UploadFilePayload> files,
    String? productId,
    String? altText,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
            contentType: DioMediaType.parse(file.mimeType),
          ),
        ),
      );
    }

    final query = <String, dynamic>{
      if (productId != null) 'productId': productId,
      if (altText != null) 'altText': altText,
    };

    try {
      final response = await _dio.post(
        '/uploads/product-images',
        data: formData,
        queryParameters: query.isEmpty ? null : query,
        onSendProgress: onProgress,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> uploadBannerImages({
    required List<UploadFilePayload> files,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
            contentType: DioMediaType.parse(file.mimeType),
          ),
        ),
      );
    }

    try {
      final response = await _dio.post(
        '/uploads/banner-images',
        data: formData,
        onSendProgress: onProgress,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteByPublicId(String publicId) async {
    try {
      await _dio.delete('/uploads/${Uri.encodeComponent(publicId)}');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProductImage(String imageId) async {
    try {
      await _dio.delete('/uploads/product-images/$imageId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> reorderImages({
    required String productId,
    required List<String> imageIds,
  }) async {
    try {
      final res = await _dio.patch(
        '/uploads/product-images/reorder',
        data: {'productId': productId, 'imageIds': imageIds},
      );
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> setFeaturedImage({
    required String productId,
    required String imageId,
  }) async {
    try {
      final res = await _dio.patch(
        '/uploads/product-images/featured',
        data: {'productId': productId, 'imageId': imageId},
      );
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static String mimeFromFilename(String name) {
    return lookupMimeType(name) ?? 'image/jpeg';
  }
}
