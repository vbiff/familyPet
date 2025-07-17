import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart';

class FamilySetupPage extends ConsumerStatefulWidget {
  const FamilySetupPage({super.key});

  @override
  ConsumerState<FamilySetupPage> createState() => _FamilySetupPageState();
}

class _FamilySetupPageState extends ConsumerState<FamilySetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createFamilyFormKey = GlobalKey<FormState>();
  final _joinFamilyFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tab controller length will be set based on user role
    final user = ref.read(currentUserProvider);
    final isChild = user?.role == UserRole.child;
    _tabController = TabController(length: isChild ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final user = ref.watch(currentUserProvider);
    final isChild = user?.role == UserRole.child;

    // If user already has a family, show different UI
    if (familyState.hasFamily) {
      return _buildAlreadyHasFamilyScreen(context, familyState);
    }

    // Listen for state changes to show feedback
    ref.listen<FamilyState>(familyNotifierProvider, (previous, next) {
      if (next.hasError) {
        _showErrorSnackBar(context, next.errorMessage!);
      } else if (next.hasFamily && previous?.hasFamily != true) {
        // Refresh user data to get updated familyId
        ref.read(authNotifierProvider.notifier).refreshUser();
        _showSuccessSnackBar(context, 'Family setup completed!');
        Navigator.of(context).pop(); // Go back to home
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Family Tasks!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isChild
                      ? 'Ask your parent for the family invite code to join and start completing tasks!'
                      : 'Create a new family or join an existing one to start managing tasks together.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: isChild
                  ? const [
                      Tab(text: 'Join Family'),
                    ]
                  : const [
                      Tab(text: 'Create Family'),
                      Tab(text: 'Join Family'),
                    ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isChild
                  ? [
                      _buildJoinFamilyTab(context, familyState),
                    ]
                  : [
                      _buildCreateFamilyTab(context, familyState),
                      _buildJoinFamilyTab(context, familyState),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFamilyTab(BuildContext context, FamilyState familyState) {
    final user = ref.watch(currentUserProvider);
    final isChild = user?.role == UserRole.child;

    // Children shouldn't see the create family tab
    if (isChild) {
      return const Center(
        child: Text(
          'Only parents can create families.\nPlease ask your parent to create one for you!',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _createFamilyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Family Name Input
            TextFormField(
              controller: _familyNameController,
              decoration: InputDecoration(
                labelText: 'Family Name',
                hintText: 'Enter your family name',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Family name is required';
                }
                if (value.trim().length < 2) {
                  return 'Family name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Family name cannot exceed 50 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              enabled: !familyState.isOperating,
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: familyState.isOperating ? null : _createFamily,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: familyState.isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Family'),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What happens next?',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• You will become the family admin\n'
                      '• An invite code will be generated\n'
                      '• Share the code with family members\n'
                      '• Start creating and managing tasks together',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinFamilyTab(BuildContext context, FamilyState familyState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _joinFamilyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Invite Code Input
            TextFormField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter 6-character invite code',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Invite code is required';
                }
                if (value.trim().length != 6) {
                  return 'Invite code must be 6 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              enabled: !familyState.isOperating,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
            ),

            const SizedBox(height: 32),

            // Join Button
            ElevatedButton(
              onPressed: familyState.isOperating ? null : _joinFamily,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: familyState.isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join Family'),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_add,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Need an invite code?',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ask a family member who already has the app to:\n'
                      '• Go to Family Settings\n'
                      '• Share the 6-character invite code\n'
                      '• Enter it here to join their family',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_createFamilyFormKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showErrorSnackBar(context, 'You must be logged in to create a family');
      return;
    }

    final success =
        await ref.read(familyNotifierProvider.notifier).createFamily(
              name: _familyNameController.text.trim(),
              createdById: user.id,
            );

    if (success) {
      // Success is handled by the listener
    }
  }

  Future<void> _joinFamily() async {
    if (!_joinFamilyFormKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final inviteCode = _inviteCodeController.text.trim().toUpperCase();

    debugPrint(
        '👶 Child user ${user.displayName} attempting to join family with code: $inviteCode');

    final success = await ref.read(familyNotifierProvider.notifier).joinFamily(
          inviteCode: inviteCode,
          userId: user.id,
        );

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Successfully joined family!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // For child users, refresh auth to ensure family_id is updated
      debugPrint('🔄 Refreshing user auth data after joining family...');
      await ref.read(authNotifierProvider.notifier).refreshUser();

      // Wait a moment then navigate back
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      // Error is already handled in the notifier
      final familyState = ref.read(familyProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(familyState.errorMessage ?? 'Failed to join family'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAlreadyHasFamilyScreen(
      BuildContext context, FamilyState familyState) {
    final family = familyState.family!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Setup'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re Already Part of a Family!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      family.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite Code: ${family.inviteCode}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${family.totalMembers} members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Go to Family'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Implement leave family functionality
                _showErrorSnackBar(
                    context, 'Leave family feature coming soon!');
              },
              child: Text(
                'Leave Current Family',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
