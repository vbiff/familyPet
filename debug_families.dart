import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  print('🔍 Debug: Checking Family Join Issue...\n');

  // Initialize Supabase with your project details
  await Supabase.initialize(
    url: 'https://evqebzbvouijnvfrorcj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2cWViemJ2b3Vpam52ZnJvcmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMwMDU0MTcsImV4cCI6MjA0ODU4MTQxN30.JKFbCZ4Fm1M8Ym3h4KRCL0x6tFNV8QVzXV3CGF7nzNo',
  );

  final supabase = Supabase.instance.client;

  try {
    print('1. Checking all families in database...');
    final familiesResponse = await supabase
        .from('families')
        .select('id, name, invite_code, created_by_id, created_at');

    print('Families found: ${familiesResponse.length}');
    for (final family in familiesResponse) {
      print(
          '  - ${family['name']} (Code: ${family['invite_code']}) - Created by: ${family['created_by_id']}');
    }

    print('\n2. Testing invite code "89ABCD"...');
    try {
      final familyByCode = await supabase
          .from('families')
          .select('id, name, invite_code, created_by_id')
          .eq('invite_code', '89ABCD')
          .single();

      print('✅ Family found with code 89ABCD:');
      print('   Name: ${familyByCode['name']}');
      print('   ID: ${familyByCode['id']}');
      print('   Created by: ${familyByCode['created_by_id']}');
    } catch (e) {
      print('❌ No family found with code "89ABCD"');
      print('   Error: $e');
    }

    print('\n3. Checking current user authentication...');
    final user = supabase.auth.currentUser;
    if (user != null) {
      print('✅ User authenticated: ${user.id}');

      print('\n4. Checking user profile...');
      final profile = await supabase
          .from('profiles')
          .select('id, email, family_id, role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        print('✅ Profile found:');
        print('   ID: ${profile['id']}');
        print('   Email: ${profile['email']}');
        print('   Family ID: ${profile['family_id']}');
        print('   Role: ${profile['role']}');
      } else {
        print('❌ No profile found for current user');
      }
    } else {
      print('❌ No user authenticated');
    }

    print('\n5. Testing RLS policies...');
    try {
      final testQuery =
          await supabase.from('families').select('invite_code').limit(1);
      print(
          '✅ RLS allows family queries: ${testQuery.length} families visible');
    } catch (e) {
      print('❌ RLS blocking family queries: $e');
    }
  } catch (e) {
    print('❌ Error during debug: $e');
  }

  print('\n6. Summary:');
  print('   - Check if families exist in database');
  print('   - Verify invite code "89ABCD" exists');
  print('   - Confirm user authentication');
  print('   - Test RLS policies');

  exit(0);
}
