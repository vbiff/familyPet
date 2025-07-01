import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/image_upload_service.dart';
import 'package:jhonny/features/family/domain/usecases/update_pet_image.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';

/// Provider for the image upload service
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ImageUploadService(supabaseClient);
});

/// Provider for the update pet image use case
final updatePetImageProvider = Provider<UpdatePetImage>((ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  final imageUploadService = ref.watch(imageUploadServiceProvider);
  return UpdatePetImage(familyRepository, imageUploadService);
});
