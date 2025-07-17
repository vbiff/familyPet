import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jhonny/core/providers/image_service_provider.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

class PhotoVerificationWidget extends ConsumerStatefulWidget {
  final Task task;
  final Function(List<String> imageUrls) onPhotosUploaded;
  final bool isRequired;

  const PhotoVerificationWidget({
    super.key,
    required this.task,
    required this.onPhotosUploaded,
    this.isRequired = false,
  });

  @override
  ConsumerState<PhotoVerificationWidget> createState() =>
      _PhotoVerificationWidgetState();
}

class _PhotoVerificationWidgetState
    extends ConsumerState<PhotoVerificationWidget> {
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // Debug: Print task image URLs to see what we're working with
    debugPrint(
        '📸 Task "${widget.task.title}" has ${widget.task.imageUrls.length} images:');
    for (int i = 0; i < widget.task.imageUrls.length; i++) {
      debugPrint('  [$i]: ${widget.task.imageUrls[i]}');
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20, // Reduced from 24
                ),
                const SizedBox(width: 6), // Reduced from 8
                Text(
                  'Photo Verification',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        // Changed from titleMedium
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.isRequired) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6), // Reduced from 8
            Text(
              'Add photos to show your completed work (optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12), // Reduced from 16

            // Display existing task images if any
            if (widget.task.hasImages) ...[
              Text(
                'Existing Photos:',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium, // Reduced from labelLarge
              ),
              const SizedBox(height: 6), // Reduced from 8
              _buildImageGrid(widget.task.imageUrls, isExisting: true),
              const SizedBox(height: 12), // Reduced from 16
            ],

            // Action buttons - Always show
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text(
                        'Photo',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text(
                        'Gallery',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Display selected images
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 10), // Reduced from 12
              Text(
                'New Photos:',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium, // Reduced from labelLarge
              ),
              const SizedBox(height: 6), // Reduced from 8
              _buildSelectedImagesGrid(),
              const SizedBox(height: 10), // Reduced from 12
              EnhancedButton.primary(
                text: _isUploading ? 'Uploading...' : 'Upload Photos',
                leadingIcon: _isUploading ? null : Icons.cloud_upload,
                isLoading: _isUploading,
                onPressed: _isUploading ? null : _uploadImages,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls, {bool isExisting = false}) {
    // Filter out empty URLs
    final validUrls = imageUrls.where((url) => url.isNotEmpty).toList();

    if (validUrls.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no valid URLs
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: validUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = validUrls[index];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildAuthenticatedImage(imageUrl),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return SizedBox(
      height: 80, // Reduced from 100
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 80, // Reduced from 100
            height: 80, // Reduced from 100
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(
                    _selectedImages[index],
                    fit: BoxFit.cover,
                    width: 80, // Reduced from 100
                    height: 80, // Reduced from 100
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthenticatedImage(String imageUrl) {
    return FutureBuilder<String?>(
      future: _getAuthenticatedImageUrl(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          debugPrint(
              '❌ Failed to get authenticated image URL: ${snapshot.error}');
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image\nunavailable',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Failed to load authenticated image: $error');
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Image\nerror',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _getAuthenticatedImageUrl(String imageUrl) async {
    try {
      final supabase = ref.read(supabaseClientProvider);

      // If the URL is already a complete URL, check if it's from Supabase storage
      if (imageUrl.startsWith('http')) {
        final uri = Uri.parse(imageUrl);

        // Check if this is a Supabase storage URL
        if (uri.path.contains('/storage/v1/object/')) {
          // Extract the bucket and path from the URL
          final pathSegments = uri.pathSegments;
          final storageIndex = pathSegments.indexOf('storage');
          if (storageIndex >= 0 && pathSegments.length > storageIndex + 4) {
            final bucket = pathSegments[storageIndex + 4];
            final filePath = pathSegments.sublist(storageIndex + 5).join('/');

            // Get a signed URL for private task-images bucket
            if (bucket == 'task-images') {
              debugPrint(
                  '🔐 Generating signed URL for private bucket: $bucket/$filePath');
              return await supabase.storage
                  .from(bucket)
                  .createSignedUrl(filePath, 3600); // 1 hour expiry
            }
          }
        }

        // For public URLs or non-Supabase URLs, return as-is
        return imageUrl;
      }

      // If it's just a path, assume it's a task image and create signed URL
      debugPrint('🔐 Creating signed URL for path: $imageUrl');
      return await supabase.storage
          .from('task-images')
          .createSignedUrl(imageUrl, 3600);
    } catch (e) {
      debugPrint('Failed to get authenticated image URL: $e');
      // Return the original URL as fallback
      return imageUrl;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('🔍 _pickImage called with source: $source');
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      debugPrint('📸 Image picker result: ${image?.path ?? "null"}');
      if (image != null) {
        debugPrint('✅ Image selected, adding to state');
        setState(() {
          _selectedImages.add(File(image.path));
        });
        debugPrint('✅ State updated with ${_selectedImages.length} images');
      } else {
        debugPrint('ℹ️ No image selected');
      }
    } catch (e) {
      debugPrint('💥 Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${_getErrorMessage(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('camera_access_denied')) {
      return 'Camera access denied';
    } else if (error.toString().contains('photo_access_denied')) {
      return 'Photo library access denied';
    } else {
      return 'Unable to access camera or photo library';
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    final imageService = ref.read(imageUploadServiceProvider);
    final List<String> newImageUrls = [];

    try {
      for (final image in _selectedImages) {
        final result = await imageService.uploadTaskVerificationImageFromFile(
          taskId: widget.task.id,
          familyId: widget.task.familyId,
          file: image,
        );

        result.fold(
          (failure) => throw Exception(failure.message),
          (imageUrl) => newImageUrls.add(imageUrl),
        );
      }

      // Combine existing and new image URLs
      final allImageUrls = [...widget.task.imageUrls, ...newImageUrls];

      widget.onPhotosUploaded(allImageUrls);

      setState(() {
        _uploadedImageUrls.addAll(newImageUrls);
        _selectedImages.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photos: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  bool get hasPhotos =>
      widget.task.hasImages ||
      _selectedImages.isNotEmpty ||
      _uploadedImageUrls.isNotEmpty;
  bool get canProceed => !widget.isRequired || hasPhotos;
}
