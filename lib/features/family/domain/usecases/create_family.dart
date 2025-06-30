import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';

class CreateFamilyParams {
  final String name;
  final String createdById;
  final Map<String, dynamic>? settings;

  const CreateFamilyParams({
    required this.name,
    required this.createdById,
    this.settings,
  });
}

class CreateFamily {
  final FamilyRepository _repository;

  CreateFamily(this._repository);

  Future<Either<Failure, Family>> call(CreateFamilyParams params) async {
    // Validate family name
    if (params.name.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Family name cannot be empty'));
    }

    if (params.name.trim().length < 2) {
      return left(const ValidationFailure(
          message: 'Family name must be at least 2 characters long'));
    }

    if (params.name.trim().length > 50) {
      return left(const ValidationFailure(
          message: 'Family name cannot exceed 50 characters'));
    }

    // Validate creator ID
    if (params.createdById.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Creator ID cannot be empty'));
    }

    // Check if user already has a family
    final existingFamilyResult =
        await _repository.getCurrentUserFamily(params.createdById);

    return existingFamilyResult.fold(
      (failure) => left(failure),
      (existingFamily) {
        if (existingFamily != null) {
          return left(const ValidationFailure(
              message: 'You are already a member of a family'));
        }

        // Create the family
        return _repository.createFamily(
          name: params.name.trim(),
          createdById: params.createdById,
          settings: params.settings,
        );
      },
    );
  }
}
