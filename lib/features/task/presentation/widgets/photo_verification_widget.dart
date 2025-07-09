import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jhonny/core/providers/image_service_provider.dart';
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
                  child: EnhancedButton.outline(
                    text: 'Photo',
                    leadingIcon: Icons.camera_alt,
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EnhancedButton.outline(
                    text: 'Gallery',
                    leadingIcon: Icons.photo_library,
                    onPressed: _isUploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
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
    return SizedBox(
      height: 80, // Reduced from 100
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${newImageUrls.length} photo(s) uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload photos: $e'),
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
