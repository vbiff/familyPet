import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/family/data/models/family_model.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';

abstract class FamilyRemoteDataSource {
  Future<FamilyModel> createFamily(FamilyModel family);
  Future<FamilyModel> getFamilyById(String familyId);
  Future<FamilyModel> getFamilyByInviteCode(String inviteCode);
  Future<FamilyModel?> getCurrentUserFamily(String userId);
  Future<String?> getUserRole(String userId);
  Future<FamilyModel> updateFamily(FamilyModel family);
  Future<void> addMemberToFamily(String familyId, String userId);
  Future<void> removeMemberFromFamily(String familyId, String userId);
  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId);
  Future<void> updateMemberRole(String familyId, String userId, String role);
  Future<String> generateNewInviteCode(String familyId);
  Future<void> leaveFamily(String familyId, String userId);
  Future<void> deleteFamily(String familyId);
  Stream<FamilyModel> watchFamily(String familyId);
  Stream<List<FamilyMemberModel>> watchFamilyMembers(String familyId);
  Future<void> updatePetImageUrl(
      {required String familyId, required String petImageUrl});
  Future<void> updatePetStageImages(
      {required String familyId, required Map<String, String> petStageImages});
  Future<String?> getFamilyPetImageUrl(String familyId);
}

class SupabaseFamilyRemoteDataSource implements FamilyRemoteDataSource {
  final SupabaseClient _client;

  SupabaseFamilyRemoteDataSource(this._client);

  @override
  Future<FamilyModel> createFamily(FamilyModel family) async {
    try {
      final response = await _client
          .from('families')
          .insert(family.toCreateJson())
          .select()
          .single();

      final familyId = response['id'];

      // Add the creator to the family as a member (this also updates their profile)
      await addMemberToFamily(familyId, family.createdById);

      return FamilyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create family: $e');
    }
  }

  @override
  Future<FamilyModel> getFamilyById(String familyId) async {
    try {
      final response =
          await _client.from('families').select().eq('id', familyId).single();

      return FamilyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get family: $e');
    }
  }

  @override
  Future<FamilyModel> getFamilyByInviteCode(String inviteCode) async {
    try {
      final response = await _client
          .from('families')
          .select()
          .eq('invite_code', inviteCode)
          .single();

      return FamilyModel.fromJson(response);
    } catch (e) {
      throw Exception('Family not found with invite code: $inviteCode');
    }
  }

  @override
  Future<FamilyModel?> getCurrentUserFamily(String userId) async {
    try {
      // First get user's family_id from profile
      final profileResponse = await _client
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .single();

      final familyId = profileResponse['family_id'];
      if (familyId == null) return null;

      // Then get the family details
      return await getFamilyById(familyId);
    } catch (e) {
      return null; // User might not have a family yet
    }
  }

  @override
  Future<String?> getUserRole(String userId) async {
    try {
      final profileResponse = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return profileResponse['role'] as String?;
    } catch (e) {
      return null; // User might not exist
    }
  }

  @override
  Future<FamilyModel> updateFamily(FamilyModel family) async {
    try {
      final response = await _client
          .from('families')
          .update(family.toJson())
          .eq('id', family.id)
          .select()
          .single();

      return FamilyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update family: $e');
    }
  }

  @override
  Future<void> addMemberToFamily(String familyId, String userId) async {
    try {
      // Get the user's role to update family's member lists
      final userResponse = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = userResponse['role'] as String;

      // Get current family to update member lists
      final familyResponse = await _client
          .from('families')
          .select('parent_ids, child_ids')
          .eq('id', familyId)
          .single();

      List<String> parentIds =
          List<String>.from(familyResponse['parent_ids'] ?? []);
      List<String> childIds =
          List<String>.from(familyResponse['child_ids'] ?? []);

      if (role == 'parent') {
        if (!parentIds.contains(userId)) {
          parentIds.add(userId);
        }
      } else {
        if (!childIds.contains(userId)) {
          childIds.add(userId);
        }
      }

      // Update family with new member lists FIRST
      await _client.from('families').update({
        'parent_ids': parentIds,
        'child_ids': childIds,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('id', familyId);

      // Then update user's profile to link them to the family
      // This order is important because of the database constraint trigger
      await _client.from('profiles').update({
        'family_id': familyId,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to add member to family: $e');
    }
  }

  @override
  Future<void> removeMemberFromFamily(String familyId, String userId) async {
    try {
      // Remove family_id from user's profile
      await _client.from('profiles').update({
        'family_id': null,
      }).eq('id', userId);

      // Get current family to update member lists
      final familyResponse = await _client
          .from('families')
          .select('parent_ids, child_ids')
          .eq('id', familyId)
          .single();

      List<String> parentIds =
          List<String>.from(familyResponse['parent_ids'] ?? []);
      List<String> childIds =
          List<String>.from(familyResponse['child_ids'] ?? []);

      parentIds.remove(userId);
      childIds.remove(userId);

      // Update family with updated member lists
      await _client.from('families').update({
        'parent_ids': parentIds,
        'child_ids': childIds,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('id', familyId);
    } catch (e) {
      throw Exception('Failed to remove member from family: $e');
    }
  }

  @override
  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    try {
      debugPrint('🔍 Getting family members for family: $familyId');

      // Get all profiles that belong to this family
      final response = await _client.from('profiles').select('''
            id, display_name, email, role, avatar_url, family_id, 
            created_at, last_login_at
          ''').eq('family_id', familyId);

      debugPrint('📊 Database returned ${response.length} profiles');

      // Get task statistics for each member
      final List<FamilyMemberModel> members = [];

      for (final profile in response) {
        try {
          final taskStatsResponse =
              await _client.rpc('get_member_task_stats', params: {
            'member_id': profile['id'],
          });

          final taskStats =
              taskStatsResponse.isNotEmpty ? taskStatsResponse[0] : {};

          // Create member model with task stats
          final memberData = Map<String, dynamic>.from(profile);
          memberData.addAll({
            'tasks_completed': taskStats['tasks_completed'] ?? 0,
            'total_points': taskStats['total_points'] ?? 0,
            'current_streak': taskStats['current_streak'] ?? 0,
            'last_task_completed_at': taskStats['last_task_completed_at'],
            'metadata': null, // Default value since column doesn't exist
          });

          members.add(FamilyMemberModel.fromJson(memberData));
        } catch (statsError) {
          // If task stats fail, create member without stats
          // TODO: Use proper logging instead of print
          // print('Task stats failed for member ${profile['id']}: $statsError');
          final memberData = Map<String, dynamic>.from(profile);
          memberData.addAll({
            'tasks_completed': 0,
            'total_points': 0,
            'current_streak': 0,
            'last_task_completed_at': null,
            'metadata': null, // Default value since column doesn't exist
          });

          members.add(FamilyMemberModel.fromJson(memberData));
        }
      }

      debugPrint(
          '✅ Successfully created ${members.length} family member models');
      return members;
    } catch (e) {
      debugPrint('🚨 Exception in getFamilyMembers: $e');
      debugPrint('🚨 Family ID: $familyId');
      throw Exception('Failed to get family members: $e');
    }
  }

  @override
  Future<void> updateMemberRole(
      String familyId, String userId, String role) async {
    try {
      await _client.from('profiles').update({
        'role': role,
      }).eq('id', userId);

      // Update family member lists based on new role
      final familyResponse = await _client
          .from('families')
          .select('parent_ids, child_ids')
          .eq('id', familyId)
          .single();

      List<String> parentIds =
          List<String>.from(familyResponse['parent_ids'] ?? []);
      List<String> childIds =
          List<String>.from(familyResponse['child_ids'] ?? []);

      // Remove from both lists first
      parentIds.remove(userId);
      childIds.remove(userId);

      // Add to appropriate list
      if (role == 'parent') {
        parentIds.add(userId);
      } else {
        childIds.add(userId);
      }

      await _client.from('families').update({
        'parent_ids': parentIds,
        'child_ids': childIds,
      }).eq('id', familyId);
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  @override
  Future<String> generateNewInviteCode(String familyId) async {
    try {
      // Generate a unique invite code
      final newInviteCode = _generateInviteCode();

      await _client.from('families').update({
        'invite_code': newInviteCode,
      }).eq('id', familyId);

      return newInviteCode;
    } catch (e) {
      throw Exception('Failed to generate new invite code: $e');
    }
  }

  @override
  Future<void> leaveFamily(String familyId, String userId) async {
    try {
      await removeMemberFromFamily(familyId, userId);
    } catch (e) {
      throw Exception('Failed to leave family: $e');
    }
  }

  @override
  Future<void> deleteFamily(String familyId) async {
    try {
      // First remove family_id from all member profiles
      await _client.from('profiles').update({
        'family_id': null,
      }).eq('family_id', familyId);

      // Then delete the family
      await _client.from('families').delete().eq('id', familyId);
    } catch (e) {
      throw Exception('Failed to delete family: $e');
    }
  }

  @override
  Stream<FamilyModel> watchFamily(String familyId) {
    return _client
        .from('families')
        .stream(primaryKey: ['id'])
        .eq('id', familyId)
        .map((data) => FamilyModel.fromJson(data.first));
  }

  @override
  Stream<List<FamilyMemberModel>> watchFamilyMembers(String familyId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .asyncMap((profiles) async {
          final List<FamilyMemberModel> members = [];

          for (final profile in profiles) {
            try {
              final taskStatsResponse =
                  await _client.rpc('get_member_task_stats', params: {
                'member_id': profile['id'],
              });

              final taskStats =
                  taskStatsResponse.isNotEmpty ? taskStatsResponse[0] : {};

              final memberData = Map<String, dynamic>.from(profile);
              memberData.addAll({
                'tasks_completed': taskStats['tasks_completed'] ?? 0,
                'total_points': taskStats['total_points'] ?? 0,
                'current_streak': taskStats['current_streak'] ?? 0,
                'last_task_completed_at': taskStats['last_task_completed_at'],
              });

              members.add(FamilyMemberModel.fromJson(memberData));
            } catch (e) {
              // If stats fail, create member without stats
              members.add(FamilyMemberModel.fromJson(profile));
            }
          }

          return members;
        });
  }

  String _generateInviteCode() {
    // Use only characters allowed by database validation: [ACDEFHJKMNPRTUVWXY347]
    const chars = 'ACDEFHJKMNPRTUVWXY347';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }

  /// Update family pet image URL
  @override
  Future<void> updatePetImageUrl({
    required String familyId,
    required String petImageUrl,
  }) async {
    try {
      await _client.from('families').update({
        'pet_image_url': petImageUrl,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('id', familyId);
    } catch (e) {
      throw Exception('Failed to update pet image URL: $e');
    }
  }

  /// Update family pet stage images
  @override
  Future<void> updatePetStageImages({
    required String familyId,
    required Map<String, String> petStageImages,
  }) async {
    try {
      await _client.from('families').update({
        'pet_stage_images': petStageImages,
        'last_activity_at': DateTime.now().toIso8601String(),
      }).eq('id', familyId);
    } catch (e) {
      throw Exception('Failed to update pet stage images: $e');
    }
  }

  /// Get family pet image URL
  @override
  Future<String?> getFamilyPetImageUrl(String familyId) async {
    try {
      final response = await _client
          .from('families')
          .select('pet_image_url')
          .eq('id', familyId)
          .maybeSingle();

      return response?['pet_image_url'] as String?;
    } catch (e) {
      throw Exception('Failed to get family pet image URL: $e');
    }
  }
}
