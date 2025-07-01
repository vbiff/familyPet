import 'dart:io';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/core/error/failures.dart';

class ImageUploadService {
  final SupabaseClient _supabaseClient;

  ImageUploadService(this._supabaseClient);

  /// Uploads a pet image to Supabase storage
  Future<Either<Failure, String>> uploadPetImage({
    required String familyId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      final path = 'pets/$familyId/$fileName';

      // Upload to pet-images bucket
      await _supabaseClient.storage
          .from('pet-images')
          .uploadBinary(path, fileBytes);

      // Get public URL
      final publicUrl =
          _supabaseClient.storage.from('pet-images').getPublicUrl(path);

      return Right(publicUrl);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to upload image: $e'));
    }
  }

  /// Uploads a pet image from file
  Future<Either<Failure, String>> uploadPetImageFromFile({
    required String familyId,
    required File file,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final fileBytes = await file.readAsBytes();

      return uploadPetImage(
        familyId: familyId,
        fileName: fileName,
        fileBytes: fileBytes,
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to read file: $e'));
    }
  }

  /// Uploads default pet stage images for a family
  Future<Either<Failure, Map<String, String>>> uploadDefaultPetImages({
    required String familyId,
  }) async {
    try {
      final Map<String, String> stageImages = {};

      // Define default pet stages
      final stages = ['egg', 'baby', 'child', 'teen', 'adult'];

      for (final stage in stages) {
        // Load asset as bytes (you'll need to implement this)

        final fileName = 'pet_$stage.png';

        // For now, we'll create placeholder URLs
        // In a real implementation, you'd load the asset bytes and upload them
        final path = 'pets/$familyId/$fileName';
        final publicUrl =
            _supabaseClient.storage.from('pet-images').getPublicUrl(path);

        stageImages[stage] = publicUrl;
      }

      return Right(stageImages);
    } catch (e) {
      return Left(
          ServerFailure(message: 'Failed to upload default images: $e'));
    }
  }

  /// Uploads a profile avatar from file
  Future<Either<Failure, String>> uploadProfileAvatarFromFile({
    required String userId,
    required File file,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_avatar.jpg';
      final path = 'profiles/$userId/$fileName';
      final fileBytes = await file.readAsBytes();

      // Upload to profile-images bucket
      await _supabaseClient.storage
          .from('profile_images')
          .uploadBinary(path, fileBytes);

      // Get public URL
      final publicUrl =
          _supabaseClient.storage.from('profile_images').getPublicUrl(path);

      return Right(publicUrl);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to upload avatar: $e'));
    }
  }

  /// Deletes a pet image from storage
  Future<Either<Failure, void>> deletePetImage({
    required String imagePath,
  }) async {
    try {
      await _supabaseClient.storage.from('pet-images').remove([imagePath]);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete image: $e'));
    }
  }
}
