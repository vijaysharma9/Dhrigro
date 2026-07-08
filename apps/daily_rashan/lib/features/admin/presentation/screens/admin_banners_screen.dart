import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../upload/data/upload_repository.dart';
import '../../../upload/presentation/providers/upload_provider.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../data/admin_repository.dart';

final adminBannersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.read(adminRepositoryProvider).getBanners();
});

class AdminBannersScreen extends ConsumerStatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  ConsumerState<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends ConsumerState<AdminBannersScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  Future<void> _uploadAndCreate() async {
    List<UploadFilePayload> payloads = [];

    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result?.files.single.bytes == null) return;
      final f = result!.files.single;
      payloads.add(
        UploadFilePayload(
          bytes: f.bytes!,
          filename: f.name,
          mimeType: UploadRepository.mimeFromFilename(f.name),
        ),
      );
    } else {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      payloads.add(
        UploadFilePayload(
          bytes: await picked.readAsBytes(),
          filename: picked.name,
          mimeType: UploadRepository.mimeFromFilename(picked.name),
        ),
      );
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter banner title')),
      );
      return;
    }

    try {
      final uploaded =
          await ref.read(uploadStateProvider.notifier).uploadBannerImages(payloads);
      final img = uploaded.first;

      await ref.read(adminRepositoryProvider).createBanner({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'imageUrl': img['imageUrl'],
        'thumbnailUrl': img['thumbnailUrl'],
        'imagePublicId': img['publicId'],
      });

      _titleController.clear();
      _subtitleController.clear();
      ref.invalidate(adminBannersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AdminApiUtils.dioMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(adminBannersProvider);
    final uploadState = ref.watch(uploadStateProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Create banner', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: uploadState.isUploading ? null : _uploadAndCreate,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload image & create banner'),
                ),
                if (uploadState.isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(value: uploadState.progress),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('All banners', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        bannersAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => AdminErrorState(
            error: e,
            title: 'Could not load banners',
            onRetry: () => ref.invalidate(adminBannersProvider),
          ),
          data: (banners) {
            if (banners.isEmpty) return const Text('No banners');
            return Column(
              children: banners.map((b) {
                final banner = b as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: (banner['thumbnailUrl'] ??
                            banner['imageUrl']) as String,
                        width: 80,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(banner['title'] as String? ?? ''),
                    subtitle: Text(banner['subtitle'] as String? ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.errorRed),
                      onPressed: () async {
                        await ref
                            .read(adminRepositoryProvider)
                            .deleteBanner(banner['id'] as String);
                        ref.invalidate(adminBannersProvider);
                      },
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
