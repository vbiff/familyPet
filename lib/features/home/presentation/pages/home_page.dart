import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:jhonny/features/auth/presentation/pages/login_page.dart';
import 'package:jhonny/features/auth/presentation/pages/profile_settings_page.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/family/presentation/pages/family_setup_page.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart';
import 'package:jhonny/features/family/presentation/widgets/family_list.dart';
import 'package:jhonny/features/home/presentation/providers/home_provider.dart';
import 'package:jhonny/features/pet/presentation/widgets/virtual_pet.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';
import 'package:jhonny/features/task/presentation/widgets/task_list.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';
import 'package:jhonny/shared/widgets/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final hasFamily = ref.watch(hasFamilyProvider);
    final familyState = ref.watch(familyProvider);

    // Load family data when user is authenticated and available
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    });

    // Auto-load family data when user becomes available and has family ID
    if (user != null &&
        user.familyId != null &&
        authState.status == AuthStatus.authenticated &&
        familyState.status == FamilyStatus.initial &&
        !familyState.isLoading) {
      Future.microtask(() {
        ref.read(familyNotifierProvider.notifier).loadCurrentFamily(user.id);
      });

      // Auto-load tasks when user becomes available
      final taskState = ref.read(taskNotifierProvider);
      if (taskState.status == TaskStateStatus.initial &&
          !taskState.isCreating &&
          user.familyId != null) {
        Future.microtask(() {
          Logger().i('🏠 Home: Loading tasks for family ID: ${user.familyId}');
          ref
              .read(taskNotifierProvider.notifier)
              .loadTasks(familyId: user.familyId!);
        });
      }
    }

    // Auto-load pet data when family becomes available and valid
    ref.listen(familyNotifierProvider, (previous, next) {
      if (next.hasFamily && next.family != null && next.family!.id.isNotEmpty) {
        final petState = ref.read(petNotifierProvider);
        if (!petState.hasPet && !petState.isLoading) {
          Future.microtask(() {
            ref
                .read(petNotifierProvider.notifier)
                .loadFamilyPet(next.family!.id);
          });
        }
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(_getGreeting(user?.displayName ?? 'User')),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            expandedHeight: 140,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Text(
                          'Welcome to FamilyPet',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage tasks and care for your virtual pets together',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => _showProfileMenu(context, ref),
                tooltip: 'Profile',
              ),
            ],
          ),

          // Error banner if needed
          if (authState.status == AuthStatus.error && authState.failure != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: EnhancedCard.elevated(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.failure!.message,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Quick stats section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _buildQuickStatsSection(context, ref),
            ),
          ),

          // Main content
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTabContent(selectedTab),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        elevation: 8,
        destinations: HomeTab.values.map((tab) {
          return NavigationDestination(
            icon: Icon(_getTabIcon(tab)),
            selectedIcon: Icon(_getTabIcon(tab), fill: 1),
            label: tab.label,
          );
        }).toList(),
      ),
      floatingActionButton:
          _buildFloatingActionButton(context, ref, selectedTab, hasFamily),
    );
  }

  Widget? _buildFloatingActionButton(
      BuildContext context, WidgetRef ref, int selectedTab, bool hasFamily) {
    // No floating action button needed
    return null;
  }

  void _navigateToFamilySetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FamilySetupPage(),
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return '$greeting, ${name.split(' ').first}!';
  }

  Widget _buildQuickStatsSection(BuildContext context, WidgetRef ref) {
    final familyMembers = ref.watch(familyMembersProvider);
    final hasFamily = ref.watch(hasFamilyProvider);
    final pendingTasks = ref.watch(pendingTasksProvider);
    final petState = ref.watch(petNotifierProvider);

    // Calculate task stats based on family status
    final user = ref.watch(currentUserProvider);
    final pendingCount =
        hasFamily && user?.familyId != null ? pendingTasks.length : 0;
    final taskValue =
        hasFamily && user?.familyId != null ? '$pendingCount' : '--';
    final taskSubtitle =
        hasFamily && user?.familyId != null ? 'Pending' : 'Setup Needed';

    // Calculate pet stats
    final pet = petState.pet;
    final petHealth = pet?.stats['health'] ?? 0;
    final petHealthValue = pet != null ? '$petHealth%' : '--';
    final petHealthSubtitle = pet != null
        ? (petHealth >= 80
            ? 'Happy'
            : petHealth >= 50
                ? 'OK'
                : 'Needs Care')
        : 'No Pet';

    return EnhancedCard.elevated(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.task_alt,
                label: 'Tasks',
                value: taskValue,
                subtitle: taskSubtitle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.pets,
                label: 'Pet Health',
                value: petHealthValue,
                subtitle: petHealthSubtitle,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.family_restroom,
                label: 'Family',
                value: hasFamily ? '${familyMembers.length}' : '0',
                subtitle: 'Members',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildTabContent(int selectedTab) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(selectedTab),
        child: _getTabWidget(selectedTab),
      ),
    );
  }

  Widget _getTabWidget(int index) {
    switch (HomeTab.values[index]) {
      case HomeTab.tasks:
        return const TaskList();
      case HomeTab.pet:
        return const VirtualPet();
      case HomeTab.family:
        return const FamilyList();
    }
  }

  IconData _getTabIcon(HomeTab tab) {
    switch (tab) {
      case HomeTab.tasks:
        return Icons.assignment_outlined;
      case HomeTab.pet:
        return Icons.pets_outlined;
      case HomeTab.family:
        return Icons.family_restroom_outlined;
    }
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to help
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
