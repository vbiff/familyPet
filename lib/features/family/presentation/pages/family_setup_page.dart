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

  // Enhanced state management
  bool _isCreatingFamily = false;
  bool _isJoiningFamily = false;
  String? _currentOperation;

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
      body: Stack(
        children: [
          Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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

          // Loading overlay
          _buildLoadingOverlay(),
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
              enabled: !_isCreatingFamily && !familyState.isOperating,
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: (_isCreatingFamily || familyState.isOperating)
                  ? null
                  : _createFamily,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreatingFamily
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
                          'Creating a Family',
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
                      'As a parent, you can create a family and invite other family members:\n'
                      '• You\'ll get a unique 6-character invite code\n'
                      '• Share the code with your children and spouse\n'
                      '• Everyone can then manage tasks together\n'
                      '• You can change the invite code anytime in settings',
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
                if (!_isValidInviteCode(value.trim().toUpperCase())) {
                  return 'Invalid invite code format';
                }
                return null;
              },
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              enabled: !_isJoiningFamily && !familyState.isOperating,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
            ),

            const SizedBox(height: 32),

            // Join Button
            ElevatedButton(
              onPressed: (_isJoiningFamily || familyState.isOperating)
                  ? null
                  : _joinFamily,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoiningFamily
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

  // ENHANCED _createFamily function
  Future<void> _createFamily() async {
    if (!_createFamilyFormKey.currentState!.validate()) return;
    if (_isCreatingFamily) return; // Prevent double-taps

    setState(() {
      _isCreatingFamily = true;
      _currentOperation = 'Creating your family...';
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to create a family');
      }

      // Validate user role
      if (user.role == UserRole.child) {
        throw Exception(
            'Only parents can create families. Children should join existing families using invite codes.');
      }

      final familyName = _familyNameController.text.trim();
      debugPrint(
          '🏗️ Creating family: $familyName for user: ${user.displayName}');

      // Use the enhanced family notifier
      final success =
          await ref.read(familyNotifierProvider.notifier).createFamily(
                name: familyName,
                createdById: user.id,
              );

      if (success && mounted) {
        _showSuccessSnackBar(
            context, '🎉 Family "$familyName" created successfully!');

        // Refresh user data to get updated familyId
        debugPrint('🔄 Refreshing user auth data after creating family...');
        await ref.read(authNotifierProvider.notifier).refreshUser();

        // Clear form
        _clearForms();

        // Wait a moment then navigate back
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('🚨 Failed to create family: $e');
      if (mounted) {
        _showErrorSnackBar(context, 'Failed to create family: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingFamily = false;
          _currentOperation = null;
        });
      }
    }
  }

  // ENHANCED _joinFamily function
  Future<void> _joinFamily() async {
    if (!_joinFamilyFormKey.currentState!.validate()) return;
    if (_isJoiningFamily) return; // Prevent double-taps

    setState(() {
      _isJoiningFamily = true;
      _currentOperation = 'Joining family...';
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('You must be logged in to join a family');
      }

      final inviteCode = _inviteCodeController.text.trim().toUpperCase();
      debugPrint(
          '🤝 User ${user.displayName} (${user.role}) joining family with code: $inviteCode');

      // Validate invite code format
      if (!_isValidInviteCode(inviteCode)) {
        throw Exception(
            'Invalid invite code format. Please check and try again.');
      }

      // Use the enhanced family notifier
      final success =
          await ref.read(familyNotifierProvider.notifier).joinFamily(
                inviteCode: inviteCode,
                userId: user.id,
              );

      if (success && mounted) {
        _showSuccessSnackBar(context, '🎉 Successfully joined family!');

        // Refresh user data to get updated familyId
        debugPrint('🔄 Refreshing user auth data after joining family...');
        await ref.read(authNotifierProvider.notifier).refreshUser();

        // Clear form
        _clearForms();

        // Wait a moment then navigate back
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('🚨 Failed to join family: $e');
      if (mounted) {
        String errorMessage = _formatJoinError(e.toString());
        _showErrorSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningFamily = false;
          _currentOperation = null;
        });
      }
    }
  }

  // NEW UTILITY FUNCTIONS

  // Validate invite code format
  bool _isValidInviteCode(String code) {
    if (code.length != 6) return false;
    // Check if code contains only allowed characters
    const allowedChars = 'ACDEFHJKMNPRTUVWXY347';
    return code.split('').every((char) => allowedChars.contains(char));
  }

  // Format error messages for better user experience
  String _formatJoinError(String error) {
    if (error.contains('Invalid invite code')) {
      return 'Invalid invite code. Please check the code and try again.';
    } else if (error.contains('already has a family') ||
        error.contains('already a member')) {
      return 'You are already a member of a family. Leave your current family first.';
    } else if (error.contains('Family not found')) {
      return 'Family not found. Please check the invite code and try again.';
    } else if (error.contains('User not found')) {
      return 'User account not found. Please try logging out and back in.';
    } else {
      return 'Failed to join family. Please try again.';
    }
  }

  // Clear form data
  void _clearForms() {
    _familyNameController.clear();
    _inviteCodeController.clear();
    _createFamilyFormKey.currentState?.reset();
    _joinFamilyFormKey.currentState?.reset();
  }

  // Retry failed operations
  Future<void> _retryOperation() async {
    if (_currentOperation?.contains('Creating') == true) {
      await _createFamily();
    } else if (_currentOperation?.contains('Joining') == true) {
      await _joinFamily();
    }
  }

  // Enhanced error display with retry option
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _retryOperation,
        ),
      ),
    );
  }

  // Enhanced success display
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading overlay during operations
  Widget _buildLoadingOverlay() {
    if (!_isCreatingFamily && !_isJoiningFamily) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _currentOperation ?? 'Processing...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
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
      body: Center(
        child: Padding(
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
                'You\'re already part of a family!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Invite Code: ${family.inviteCode}',
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${family.totalMembers} member${family.totalMembers != 1 ? 's' : ''}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
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
      ),
    );
  }
}
