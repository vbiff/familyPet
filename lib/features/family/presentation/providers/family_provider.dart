import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/features/family/data/datasources/family_remote_datasource.dart';
import 'package:jhonny/features/family/data/repositories/supabase_family_repository.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';
import 'package:jhonny/features/family/domain/usecases/create_family.dart';
import 'package:jhonny/features/family/domain/usecases/join_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_current_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_family_members.dart';
import 'package:jhonny/features/family/presentation/providers/family_notifier.dart'
    as family_notifier;
import 'package:jhonny/features/family/presentation/providers/family_state.dart';

// UUID Provider
final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

// Data Source Provider
final familyRemoteDataSourceProvider = Provider<FamilyRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseFamilyRemoteDataSource(supabaseClient);
});

// Repository Provider
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final remoteDataSource = ref.watch(familyRemoteDataSourceProvider);
  final uuid = ref.watch(uuidProvider);
  return SupabaseFamilyRepository(remoteDataSource, uuid);
});

// Use Cases Providers
final createFamilyUseCaseProvider = Provider<CreateFamily>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return CreateFamily(repository);
});

final joinFamilyUseCaseProvider = Provider<JoinFamily>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return JoinFamily(repository);
});

final getCurrentFamilyUseCaseProvider = Provider<GetCurrentFamily>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return GetCurrentFamily(repository);
});

final getFamilyMembersUseCaseProvider = Provider<GetFamilyMembers>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return GetFamilyMembers(repository);
});

// Family State Notifier Provider
final familyNotifierProvider =
    StateNotifierProvider<family_notifier.FamilyNotifier, FamilyState>((ref) {
  final createFamily = ref.watch(createFamilyUseCaseProvider);
  final joinFamily = ref.watch(joinFamilyUseCaseProvider);
  final getCurrentFamily = ref.watch(getCurrentFamilyUseCaseProvider);
  final getFamilyMembers = ref.watch(getFamilyMembersUseCaseProvider);
  final familyRepository = ref.watch(familyRepositoryProvider);

  return family_notifier.FamilyNotifier(
    createFamily: createFamily,
    joinFamily: joinFamily,
    getCurrentFamily: getCurrentFamily,
    getFamilyMembers: getFamilyMembers,
    familyRepository: familyRepository,
  );
});

// Family state provider (convenience provider)
final familyProvider = Provider<FamilyState>((ref) {
  return ref.watch(familyNotifierProvider);
});

// Current family provider (convenience provider)
final currentFamilyProvider = Provider((ref) {
  return ref.watch(familyNotifierProvider).family;
});

// Family members provider (convenience provider)
final familyMembersProvider = Provider((ref) {
  try {
    return ref.watch(familyNotifierProvider).members;
  } catch (e) {
    // Handle disposed provider errors during sign out
    if (e.toString().contains('disposed') ||
        e.toString().contains('Bad state')) {
      return <dynamic>[]; // Return empty list as safe default
    }
    rethrow;
  }
});

// Has family provider (convenience provider)
final hasFamilyProvider = Provider<bool>((ref) {
  try {
    return ref.watch(familyNotifierProvider).hasFamily;
  } catch (e) {
    // Handle disposed provider errors during sign out
    if (e.toString().contains('disposed') ||
        e.toString().contains('Bad state')) {
      return false; // Return false as safe default
    }
    rethrow;
  }
});
