import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart';
import 'package:jhonny/features/family/presentation/pages/family_setup_page.dart';
import 'package:jhonny/features/family/presentation/pages/family_settings_page.dart';
import 'package:jhonny/features/family/presentation/pages/child_invite_qr_page.dart';

class FamilyList extends ConsumerStatefulWidget {
  const FamilyList({super.key});

  @override
  ConsumerState<FamilyList> createState() => _FamilyListState();
}

class _FamilyListState extends ConsumerState<FamilyList> {
  bool _hasLoadedFamily = false;

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final user = ref.watch(currentUserProvider);

    // Load family data if not loaded yet for any authenticated user
    if (!_hasLoadedFamily && user != null && !familyState.isLoading) {
      Future.microtask(() {
        ref.read(familyNotifierProvider.notifier).loadCurrentFamily(user.id);
        _hasLoadedFamily = true;
      });
    }

    return _buildContent(context, familyState);
  }

  Widget _buildContent(BuildContext context, FamilyState familyState) {
    if (familyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (familyState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load family',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              familyState.errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  ref
                      .read(familyNotifierProvider.notifier)
                      .loadCurrentFamily(user.id);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!familyState.hasFamily) {
      return _buildNoFamilyState(context);
    }

    return _buildFamilyContent(context, familyState);
  }

  Widget _buildNoFamilyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Family Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a family or join an existing one to start managing tasks together.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToFamilySetup(context),
            icon: const Icon(Icons.add),
            label: const Text('Setup Family'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFamilySetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FamilySetupPage(),
      ),
    );
  }

  Widget _buildFamilyContent(BuildContext context, FamilyState familyState) {
    final family = familyState.family!;
    final members = familyState.members;

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh family member statistics
        await ref.read(familyNotifierProvider.notifier).refreshFamilyMembers();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Family overview card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Family header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.family_restroom,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                family.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${family.totalMembers} members',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChildInviteQrPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add),
                              tooltip: 'Invite Child',
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FamilySettingsPage(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.settings,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              tooltip: 'Family Settings',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFamilyStat(
                            context,
                            'Total Points',
                            '${members.fold(0, (sum, member) => sum + member.totalPoints)}',
                            Icons.stars,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFamilyStat(
                            context,
                            'Tasks Done',
                            '${members.fold(0, (sum, member) => sum + member.tasksCompleted)}',
                            Icons.task_alt,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Text(
                  'Family Members',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (familyState.isLoadingMembers)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                // Debug button to manually refresh family members
                if (kDebugMode) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      debugPrint('🔄 Manual refresh triggered by user');
                      ref
                          .read(familyNotifierProvider.notifier)
                          .refreshFamilyMembers();
                    },
                    tooltip: 'Refresh Members (Debug)',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            if (familyState.isLoadingMembers && members.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (members.isEmpty)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No family members found',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        if (familyState.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${familyState.errorMessage}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              // Try to reload family members
                              ref
                                  .read(familyNotifierProvider.notifier)
                                  .refreshFamilyMembers();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              // Family members list
              ...members.map((member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: member.role.name == 'parent'
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.tertiary,
                              child: Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Member info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        member.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: member.isOnline
                                              ? Colors.green
                                              : Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${member.roleDisplayName} • ${member.statusText}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildMemberBadge(
                                        context,
                                        '${member.tasksCompleted} tasks',
                                        Icons.task_alt,
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildMemberBadge(
                                        context,
                                        '${member.totalPoints} pts',
                                        Icons.stars,
                                        Theme.of(context).colorScheme.tertiary,
                                      ),
                                      if (member.hasActiveStreak) ...[
                                        const SizedBox(width: 8),
                                        _buildMemberBadge(
                                          context,
                                          '${member.currentStreak}🔥',
                                          Icons.local_fire_department,
                                          Colors.orange,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberBadge(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
