import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';
import 'package:jhonny/features/family/domain/entities/family.dart'
    as family_entity;
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart'
    as family_state;
import 'package:jhonny/features/family/presentation/pages/child_invite_qr_page.dart';
import 'package:jhonny/shared/widgets/enhanced_card.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

class FamilySettingsPage extends ConsumerStatefulWidget {
  const FamilySettingsPage({super.key});

  @override
  ConsumerState<FamilySettingsPage> createState() => _FamilySettingsPageState();
}

class _FamilySettingsPageState extends ConsumerState<FamilySettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load family members after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final family = ref.read(familyProvider).family;
      if (family != null) {
        ref.read(familyNotifierProvider.notifier).loadFamilyMembers(family.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (!familyState.hasFamily || familyState.family == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Settings'),
        ),
        body: const Center(
          child: Text('No family found'),
        ),
      );
    }

    final family = familyState.family!;
    final isCreator = currentUser?.id == family.createdById;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFamilyInfoCard(family),
            const SizedBox(height: 16),
            _buildMembersCard(familyState, isCreator),
            const SizedBox(height: 16),
            _buildInviteCodeCard(family),
            const SizedBox(height: 16),
            _buildFamilyActionsCard(family, isCreator),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyInfoCard(family_entity.Family family) {
    return EnhancedCard.elevated(
      title: 'Family Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.family_restroom,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(family.name),
            subtitle: Text('Created ${_formatDate(family.createdAt)}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditFamilyNameDialog(family),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Members', '${family.totalMembers}'),
              _buildStatItem('Parents', '${family.parentIds.length}'),
              _buildStatItem('Children', '${family.childIds.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard(
      family_state.FamilyState familyState, bool isCreator) {
    final members = familyState.members;

    return EnhancedCard.elevated(
      title: 'Family Members',
      child: Column(
        children: [
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Loading members...'),
            )
          else
            ...members.map((member) => _buildMemberTile(member, isCreator)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(FamilyMemberModel member, bool canManage) {
    final currentUser = ref.read(currentUserProvider);
    final isCurrentUser = currentUser?.id == member.id;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(member.displayName[0].toUpperCase())
            : null,
      ),
      title: Text(member.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.role.name.toUpperCase()),
          if (member.tasksCompleted > 0)
            Text(
                '${member.tasksCompleted} tasks • ${member.totalPoints} points'),
        ],
      ),
      trailing: canManage && !isCurrentUser
          ? PopupMenuButton<String>(
              onSelected: (action) => _handleMemberAction(action, member),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz),
                      const SizedBox(width: 8),
                      Text(
                          'Change to ${member.role == UserRole.parent ? 'Child' : 'Parent'}'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Family',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildInviteCodeCard(family_entity.Family family) {
    return EnhancedCard.elevated(
      title: 'Invite Code',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  family.inviteCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code with family members',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EnhancedButton.outline(
                  text: 'Copy Code',
                  onPressed: () => _copyInviteCode(family.inviteCode),
                  leadingIcon: Icons.copy,
                  size: EnhancedButtonSize.small,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnhancedButton.outline(
                  text: 'Generate',
                  onPressed: () => _generateNewInviteCode(family),
                  leadingIcon: Icons.refresh,
                  size: EnhancedButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyActionsCard(family_entity.Family family, bool isCreator) {
    final currentUser = ref.read(currentUserProvider);

    return EnhancedCard.elevated(
      title: 'Family Actions',
      child: Column(
        children: [
          // Add Invite Child option for parents
          if (currentUser?.role == UserRole.parent) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.qr_code,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Invite Child'),
              subtitle:
                  const Text('Generate QR code to add a child to your family'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChildInviteQrPage(),
                  ),
                );
              },
            ),
            if (!isCreator) const Divider(),
          ],
          if (!isCreator) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Leave Family'),
              subtitle: const Text('You will lose access to family tasks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLeaveFamilyDialog(family),
            ),
          ],
          if (isCreator) ...[
            if (currentUser?.role == UserRole.parent) const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete Family'),
              subtitle:
                  const Text('Permanently delete this family and all data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDeleteFamilyDialog(family),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _generateNewInviteCode(family_entity.Family family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate New Invite Code'),
        content: const Text(
          'This will invalidate the current invite code. Family members will need the new code to join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(familyNotifierProvider.notifier)
          .generateNewInviteCode(family.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New invite code generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showEditFamilyNameDialog(family_entity.Family family) async {
    final controller = TextEditingController(text: family.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Family Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Family Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != family.name) {
      final updatedFamily = family.copyWith(name: newName);
      await ref
          .read(familyNotifierProvider.notifier)
          .updateFamily(updatedFamily);
    }
  }

  Future<void> _handleMemberAction(
      String action, FamilyMemberModel member) async {
    switch (action) {
      case 'change_role':
        await _changeMemberRole(member);
        break;
      case 'remove':
        await _removeMember(member);
        break;
    }
  }

  Future<void> _changeMemberRole(FamilyMemberModel member) async {
    final newRole =
        member.role == UserRole.parent ? UserRole.child : UserRole.parent;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Member Role'),
        content: Text(
          'Change ${member.displayName}\'s role from ${member.role.name} to ${newRole.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final family = ref.read(familyProvider).family!;
      final success =
          await ref.read(familyNotifierProvider.notifier).updateMemberRole(
                familyId: family.id,
                userId: member.id,
                role: newRole.name,
              );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${member.displayName}\'s role updated to ${newRole.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(FamilyMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text(
          'Remove ${member.displayName} from the family? They will lose access to family tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final family = ref.read(familyProvider).family!;
      final success = await ref
          .read(familyNotifierProvider.notifier)
          .removeMemberFromFamily(
            familyId: family.id,
            userId: member.id,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} removed from family'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showLeaveFamilyDialog(family_entity.Family family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to leave "${family.name}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Warning',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• You will lose access to family tasks\n'
                    '• Your progress and statistics will remain\n'
                    '• You can rejoin using the invite code',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave Family'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveFamily(family);
    }
  }

  Future<void> _showDeleteFamilyDialog(family_entity.Family family) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This action cannot be undone. All family data including tasks, progress, and the pet will be permanently deleted.'),
            const SizedBox(height: 16),
            const Text('Type "DELETE" to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return TextButton(
                onPressed: value.text == 'DELETE'
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete Family'),
              );
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteFamily(family);
    }
  }

  Future<void> _leaveFamily(family_entity.Family family) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final success = await ref.read(familyNotifierProvider.notifier).leaveFamily(
          familyId: family.id,
          userId: currentUser.id,
        );

    if (success) {
      // Refresh user data to clear familyId
      ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully left "${family.name}"'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(); // Go back to previous screen
      }
    }
  }

  Future<void> _deleteFamily(family_entity.Family family) async {
    final success =
        await ref.read(familyNotifierProvider.notifier).deleteFamily(family.id);

    if (success) {
      // Refresh user data to clear familyId
      ref.read(authNotifierProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(); // Go back to previous screen
      }
    }
  }
}
