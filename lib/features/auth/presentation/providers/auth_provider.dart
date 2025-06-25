import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/repositories/auth_repository.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_notifier.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(supabaseClient);
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});
