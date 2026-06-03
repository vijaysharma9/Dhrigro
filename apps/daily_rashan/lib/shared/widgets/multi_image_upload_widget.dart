import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../features/upload/data/upload_repository.dart';
import '../../features/upload/presentation/providers/upload_provider.dart';

class ProductImageItem {
  ProductImageItem({
    this.id,
    this.imageUrl,
    this.thumbnailUrl,
    this.publicId,
    this.localBytes,
    this.isFeatured = false,
    this.sortOrder = 0,
  });

  String? id;
  String? imageUrl;
  String? thumbnailUrl;
  String? publicId;
  Uint8List? localBytes;
  bool isFeatured;
  int sortOrder;
}

class MultiImageUploadWidget extends ConsumerStatefulWidget {
  const MultiImageUploadWidget({
    super.key,
    required this.productId,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  final String? productId;
  final List<ProductImageItem> images;
  final ValueChanged<List<ProductImageItem>> onImagesChanged;
  final int maxImages;

  @override
  ConsumerState<MultiImageUploadWidget> createState() =>
      _MultiImageUploadWidgetState();
}

class _MultiImageUploadWidgetState
    extends ConsumerState<MultiImageUploadWidget> {
  Future<void> _pickImages() async {
    if (widget.images.length >= widget.maxImages) {
      _showSnack('Maximum ${widget.maxImages} images allowed');
      return;
    }

    List<UploadFilePayload> payloads = [];

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      for (final f in result.files) {
        if (f.bytes == null) continue;
        payloads.add(
          UploadFilePayload(
            bytes: f.bytes!,
            filename: f.name,
            mimeType: UploadRepository.mimeFromFilename(f.name),
          ),
        );
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 85);
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        payloads.add(
          UploadFilePayload(
            bytes: bytes,
            filename: x.name,
            mimeType: UploadRepository.mimeFromFilename(x.name),
          ),
        );
      }
    }

    if (payloads.isEmpty) return;
    await _upload(payloads);
  }

  Future<void> _upload(List<UploadFilePayload> payloads) async {
    try {
      final uploaded = await ref
          .read(uploadStateProvider.notifier)
          .uploadProductImages(
            files: payloads,
            productId: widget.productId,
          );

      final updated = [...widget.images];
      for (final img in uploaded) {
        updated.add(
          ProductImageItem(
            id: img['id'] as String?,
            imageUrl: img['imageUrl'] as String?,
            thumbnailUrl: img['thumbnailUrl'] as String?,
            publicId: img['publicId'] as String?,
            isFeatured: img['isFeatured'] as bool? ?? false,
            sortOrder: img['sortOrder'] as int? ?? updated.length,
          ),
        );
      }
      widget.onImagesChanged(updated);
      _showSnack('${uploaded.length} image(s) uploaded');
    } catch (e) {
      _showSnack('Upload failed: $e');
    }
  }

  Future<void> _removeImage(int index) async {
    final item = widget.images[index];
    try {
      if (item.id != null) {
        await ref.read(uploadRepositoryProvider).deleteProductImage(item.id!);
      } else if (item.publicId != null) {
        await ref
            .read(uploadRepositoryProvider)
            .deleteByPublicId(item.publicId!);
      }
      final updated = [...widget.images]..removeAt(index);
      widget.onImagesChanged(updated);
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  Future<void> _setFeatured(int index) async {
    final item = widget.images[index];
    if (widget.productId == null || item.id == null) {
      final updated = widget.images.map((img) {
        return ProductImageItem(
          id: img.id,
          imageUrl: img.imageUrl,
          thumbnailUrl: img.thumbnailUrl,
          publicId: img.publicId,
          localBytes: img.localBytes,
          isFeatured: img == item,
          sortOrder: img.sortOrder,
        );
      }).toList();
      widget.onImagesChanged(updated);
      return;
    }

    try {
      final result = await ref.read(uploadRepositoryProvider).setFeaturedImage(
            productId: widget.productId!,
            imageId: item.id!,
          );
      final updated = result.map((e) {
        final m = e as Map<String, dynamic>;
        return ProductImageItem(
          id: m['id'] as String?,
          imageUrl: m['imageUrl'] as String?,
          thumbnailUrl: m['thumbnailUrl'] as String?,
          publicId: m['publicId'] as String?,
          isFeatured: m['isFeatured'] as bool? ?? false,
          sortOrder: m['sortOrder'] as int? ?? 0,
        );
      }).toList();
      widget.onImagesChanged(updated);
    } catch (e) {
      _showSnack('Failed to set featured image');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadStateProvider);
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width > 900 ? 5 : (width > 600 ? 4 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product images',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (widget.productId == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Save product first to upload images to Cloudinary',
              style: TextStyle(color: AppColors.orangeAccent, fontSize: 12),
            ),
          ),
        InkWell(
          onTap: widget.productId == null ? null : _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              color: const Color(0xFFF9FAFB),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: AppColors.textGrey,
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Click to browse images (jpg, png, webp • max 5MB)'
                      : 'Tap to add images (jpg, png, webp • max 5MB)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.productId == null ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload images'),
                ),
                if (uploadState.isUploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: uploadState.progress),
                  const SizedBox(height: 4),
                  Text(
                    '${(uploadState.progress * 100).toStringAsFixed(0)}% uploaded',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: widget.images.length,
            itemBuilder: (_, index) => _ImageTile(
              item: widget.images[index],
              onRemove: () => _removeImage(index),
              onSetFeatured: () => _setFeatured(index),
            ),
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.item,
    required this.onRemove,
    required this.onSetFeatured,
  });

  final ProductImageItem item;
  final VoidCallback onRemove;
  final VoidCallback onSetFeatured;

  @override
  Widget build(BuildContext context) {
    final displayUrl = item.thumbnailUrl ?? item.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.localBytes != null)
            Image.memory(item.localBytes!, fit: BoxFit.cover)
          else if (displayUrl != null)
            CachedNetworkImage(imageUrl: displayUrl, fit: BoxFit.cover)
          else
            Container(color: Colors.grey.shade200),
          if (item.isFeatured)
            const Positioned(
              top: 8,
              left: 8,
              child: Chip(
                label: Text('Featured', style: TextStyle(fontSize: 10)),
                backgroundColor: AppColors.primaryGreen,
                labelStyle: TextStyle(color: Colors.white),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.errorRed,
              ),
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navyBlue,
              ),
              icon: Icon(
                item.isFeatured ? Icons.star : Icons.star_border,
                size: 18,
              ),
              onPressed: onSetFeatured,
            ),
          ),
        ],
      ),
    );
  }
}
