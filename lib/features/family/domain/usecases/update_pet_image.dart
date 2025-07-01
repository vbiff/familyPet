import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';
import 'package:jhonny/core/services/image_upload_service.dart';
import 'dart:io';
import 'dart:typed_data';

class UpdatePetImage {
  final FamilyRepository _familyRepository;
  final ImageUploadService _imageUploadService;

  UpdatePetImage(this._familyRepository, this._imageUploadService);

  /// Update pet image from file
  Future<Either<Failure, String>> updateFromFile({
    required String familyId,
    required File imageFile,
  }) async {
    try {
      // Upload image to Supabase storage
      final uploadResult = await _imageUploadService.uploadPetImageFromFile(
        familyId: familyId,
        file: imageFile,
      );

      return uploadResult.fold(
        (failure) => Left(failure),
        (imageUrl) async {
          // Update family pet image URL
          final updateResult = await _familyRepository.updatePetImageUrl(
            familyId: familyId,
            petImageUrl: imageUrl,
          );

          return updateResult.fold(
            (failure) => Left(failure),
            (_) => Right(imageUrl),
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update pet image: $e'));
    }
  }

  /// Update pet image from bytes
  Future<Either<Failure, String>> updateFromBytes({
    required String familyId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Upload image to Supabase storage
      final uploadResult = await _imageUploadService.uploadPetImage(
        familyId: familyId,
        fileName: fileName,
        fileBytes: imageBytes,
      );

      return uploadResult.fold(
        (failure) => Left(failure),
        (imageUrl) async {
          // Update family pet image URL
          final updateResult = await _familyRepository.updatePetImageUrl(
            familyId: familyId,
            petImageUrl: imageUrl,
          );

          return updateResult.fold(
            (failure) => Left(failure),
            (_) => Right(imageUrl),
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update pet image: $e'));
    }
  }

  /// Update pet stage images for the family
  Future<Either<Failure, Map<String, String>>> updateStageImages({
    required String familyId,
    required Map<String, String> stageImageUrls,
  }) async {
    try {
      final updateResult = await _familyRepository.updatePetStageImages(
        familyId: familyId,
        petStageImages: stageImageUrls,
      );

      return updateResult.fold(
        (failure) => Left(failure),
        (_) => Right(stageImageUrls),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update stage images: $e'));
    }
  }

  /// Set up default pet images for a family
  Future<Either<Failure, Map<String, String>>> setupDefaultImages({
    required String familyId,
  }) async {
    try {
      // Upload default pet images
      final uploadResult = await _imageUploadService.uploadDefaultPetImages(
        familyId: familyId,
      );

      return uploadResult.fold(
        (failure) => Left(failure),
        (stageImages) async {
          // Update family pet stage images
          final updateResult = await _familyRepository.updatePetStageImages(
            familyId: familyId,
            petStageImages: stageImages,
          );

          return updateResult.fold(
            (failure) => Left(failure),
            (_) => Right(stageImages),
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to setup default images: $e'));
    }
  }
}
