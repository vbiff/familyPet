import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (e) {
    if (kDebugMode) {
      print('Warning: Supabase client not available: $e');
    }
    throw Exception(
        'Supabase not initialized. Please check your configuration.');
  }
});

final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  try {
    return Supabase.instance.client.auth;
  } catch (e) {
    if (kDebugMode) {
      print('Warning: Supabase auth not available: $e');
    }
    throw Exception(
        'Supabase auth not initialized. Please check your configuration.');
  }
});

// Provider for main.dart compatibility
final supabaseProvider = FutureProvider<SupabaseClient>((ref) async {
  try {
    return Supabase.instance.client;
  } catch (e) {
    if (kDebugMode) {
      print('Warning: Supabase client not available: $e');
    }
    throw Exception(
        'Supabase not initialized. Please check your configuration.');
  }
});
