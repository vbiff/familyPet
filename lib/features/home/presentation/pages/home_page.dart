import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:jhonny/features/analytics/presentation/pages/family_dashboard_page.dart';
import 'package:jhonny/features/auth/presentation/pages/login_page.dart';
import 'package:jhonny/features/auth/presentation/pages/profile_settings_page.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/family/presentation/pages/family_settings_page.dart';
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
import 'package:jhonny/shared/widgets/theme_toggle.dart';
import 'package:jhonny/main.dart'; // To access themeService
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:jhonny/features/task/presentation/pages/archive_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final familyState = ref.watch(familyProvider);

    // Load family data when user is authenticated and available
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      } else if (next.status == AuthStatus.authenticated &&
          previous?.user?.id != next.user?.id) {
        // User changed - reset family provider and refresh user data
        ref.read(familyNotifierProvider.notifier).reset();
        // Refresh user data to ensure it's up-to-date
        ref.read(authNotifierProvider.notifier).refreshUser();
      }
    });

    // Auto-load family data when user becomes available (regardless of family ID)
    if (user != null &&
        authState.status == AuthStatus.authenticated &&
        familyState.status == FamilyStatus.initial &&
        !familyState.isLoading) {
      Future.microtask(() {
        ref.read(familyNotifierProvider.notifier).loadCurrentFamily(user.id);
      });

      // Auto-load tasks only when user has a family
      if (user.familyId != null) {
        final taskState = ref.read(taskNotifierProvider);
        if (taskState.status == TaskStateStatus.initial &&
            !taskState.isCreating) {
          Future.microtask(() {
            Logger()
                .i('🏠 Home: Loading tasks for family ID: ${user.familyId}');
            ref
                .read(taskNotifierProvider.notifier)
                .loadTasks(familyId: user.familyId!);

            // Set up callback to refresh family statistics when tasks are updated
            ref
                .read(taskNotifierProvider.notifier)
                .setOnTaskUpdatedCallback(() {
              ref.read(familyNotifierProvider.notifier).refreshFamilyMembers();
            });
          });
        }
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
      appBar: AppBar(
        title:
            FittedBox(child: Text(_getGreeting(user?.displayName ?? 'User'))),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          CompactThemeToggle(
            themeService: themeService,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileMenu(context, ref),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner if needed
          if (authState.status == AuthStatus.error && authState.failure != null)
            Container(
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabContentSwitcher(
                selectedTab: selectedTab,
                getTabWidget: _getTabWidget,
              ),
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
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 5) {
      greeting = 'Good night';
    } else if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour < 24) {
      greeting = 'Good evening';
    } else {
      greeting = 'Welcome';
    }

    return '$greeting, ${name.split(' ').first}!';
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
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Family Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilyDashboardPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Family Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilySettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archived Tasks'),
              subtitle: const Text('View and manage archived tasks'),
              onTap: () async {
                Navigator.pop(context);
                debugPrint('🔄 Home: Navigating to Archive page');
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ArchivePage(),
                  ),
                );
                debugPrint('✅ Home: Returned from Archive page');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Manage app notification settings'),
              onTap: () {
                Navigator.pop(context);
                _openNotificationSettings(context);
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

  void _openNotificationSettings(BuildContext context) async {
    // Store the scaffold messenger reference before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      // First, show a dialog explaining what will happen
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Settings'),
          content: const Text(
            'This will open your phone\'s notification settings for Jhonny. '
            'You can enable or disable notifications, set notification sounds, '
            'and customize notification preferences.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        // Open the notification settings for this app
        await _openPlatformNotificationSettings();
      }
    } catch (e) {
      // If opening notification settings fails, show an error
      // Use the stored scaffold messenger reference
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Could not open notification settings: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openPlatformNotificationSettings() async {
    try {
      if (Platform.isIOS) {
        // For iOS, open the app's notification settings in Settings app
        final url = Uri.parse('app-settings:');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to general Settings app
          final settingsUrl = Uri.parse('app-settings:root=NOTIFICATIONS_ID');
          if (await canLaunchUrl(settingsUrl)) {
            await launchUrl(settingsUrl, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not open iOS settings');
          }
        }
      } else if (Platform.isAndroid) {
        // For Android, open the app's notification settings
        const packageName = 'com.example.jhonny';
        final url = Uri.parse(
            'android.settings.APP_NOTIFICATION_SETTINGS?package=$packageName');

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to general notification settings
          final fallbackUrl =
              Uri.parse('android.settings.NOTIFICATION_SETTINGS');
          if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not open Android settings');
          }
        }
      } else {
        throw Exception('Platform not supported');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class TabContentSwitcher extends StatelessWidget {
  final int selectedTab;
  final Widget Function(int) getTabWidget;

  const TabContentSwitcher({
    super.key,
    required this.selectedTab,
    required this.getTabWidget,
  });

  @override
  Widget build(BuildContext context) {
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
        child: getTabWidget(selectedTab),
      ),
    );
  }
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
