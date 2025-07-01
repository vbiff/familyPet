import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/core/providers/image_service_provider.dart';
import 'package:jhonny/shared/widgets/widgets.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  static final _logger = Logger();

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _displayNameController.text = user.displayName;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Section
              _buildAvatarSection(context, user),

              const SizedBox(height: 40),

              // Profile Information Section
              _buildProfileInfoSection(context, user),

              const SizedBox(height: 32),

              // Account Settings Section
              _buildAccountSettingsSection(context, user),

              const SizedBox(height: 40),

              // Save Button
              _buildSaveButton(context),

              const SizedBox(height: 20),

              // Sign Out Button
              _buildSignOutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, User user) {
    return Column(
      children: [
        // Avatar with upload overlay
        Stack(
          alignment: Alignment.center,
          children: [
            // Avatar Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildAvatarImage(user.avatarUrl),
              ),
            ),

            // Upload Progress Overlay
            if (_isUploadingAvatar)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // Camera Icon Overlay
            if (!_isUploadingAvatar)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Username
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),

        // Role Badge
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            user.role.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        memCacheWidth: 240, // 2x for high DPI displays
        memCacheHeight: 240,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Icon(
            Icons.person,
            size: 60,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Icon(
            Icons.person,
            size: 60,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Icon(
          Icons.person,
          size: 60,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
  }

  Widget _buildProfileInfoSection(BuildContext context, User user) {
    return EnhancedCard(
      title: 'Profile Information',
      child: Column(
        children: [
          // Display Name Field
          EnhancedInput(
            controller: _displayNameController,
            label: 'Display Name',
            hint: 'Enter your display name',
            leading: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Display name is required';
              }
              if (value.trim().length < 2) {
                return 'Display name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Member Since
          _buildInfoRow(
            context,
            'Member Since',
            _formatDate(user.createdAt),
            Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 12),

          // Last Login
          _buildInfoRow(
            context,
            'Last Login',
            _formatDate(user.lastLoginAt),
            Icons.login_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection(BuildContext context, User user) {
    return EnhancedCard(
      title: 'Account Settings',
      child: Column(
        children: [
          // Change Password
          _buildSettingsTile(
            context,
            'Change Password',
            'Update your account password',
            Icons.lock_outline,
            onTap: _showChangePasswordDialog,
          ),

          const Divider(height: 1),

          // Reset Password
          _buildSettingsTile(
            context,
            'Reset Password',
            'Send password reset email',
            Icons.email_outlined,
            onTap: _showResetPasswordDialog,
          ),

          const Divider(height: 1),

          // Delete Account
          _buildSettingsTile(
            context,
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_outline,
            onTap: _showDeleteAccountDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDestructive ? Theme.of(context).colorScheme.error : null,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: EnhancedButton.primary(
        text: 'Save Changes',
        leadingIcon: Icons.save,
        isLoading: _isLoading,
        onPressed: _isLoading ? null : _saveProfile,
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: EnhancedButton.outline(
        text: 'Sign Out',
        leadingIcon: Icons.logout,
        foregroundColor: Theme.of(context).colorScheme.error,
        onPressed: _signOut,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Image picker methods
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (ref.read(currentUserProvider)?.avatarUrl != null)
              ListTile(
                leading: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _cropAndUploadImage(File(pickedFile.path));
      }
    } catch (e) {
      _logger.e('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _cropAndUploadImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        await _uploadAvatar(File(croppedFile.path));
      }
    } catch (e) {
      _logger.e('Error cropping image: $e');
      _showErrorSnackBar('Failed to crop image');
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final imageUploadService = ref.read(imageUploadServiceProvider);

      final uploadResult = await imageUploadService.uploadProfileAvatarFromFile(
        userId: user.id,
        file: imageFile,
      );

      uploadResult.fold(
        (failure) {
          _logger.e('Avatar upload failed: ${failure.message}');
          _showErrorSnackBar('Failed to upload avatar');
        },
        (avatarUrl) async {
          // Update user profile with new avatar URL
          await ref.read(authNotifierProvider.notifier).updateProfile(
                avatarUrl: avatarUrl,
              );

          // Refresh user to get updated avatar
          await ref.read(authNotifierProvider.notifier).refreshUser();

          _showSuccessSnackBar('Avatar updated successfully!');
        },
      );
    } catch (e) {
      _logger.e('Error uploading avatar: $e');
      _showErrorSnackBar('Failed to upload avatar');
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            avatarUrl: '',
          );

      await ref.read(authNotifierProvider.notifier).refreshUser();

      _showSuccessSnackBar('Avatar removed successfully!');
    } catch (e) {
      _logger.e('Error removing avatar: $e');
      _showErrorSnackBar('Failed to remove avatar');
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  // Profile management methods
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            displayName: _displayNameController.text.trim(),
          );

      await ref.read(authNotifierProvider.notifier).refreshUser();

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      _logger.e('Error saving profile: $e');
      _showErrorSnackBar('Failed to update profile');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  // Dialog methods
  void _showChangePasswordDialog() {
    // TODO: Implement change password dialog
    _showInfoSnackBar('Change password feature coming soon!');
  }

  void _showResetPasswordDialog() {
    // TODO: Implement reset password dialog
    _showInfoSnackBar('Reset password feature coming soon!');
  }

  void _showDeleteAccountDialog() {
    // TODO: Implement delete account dialog
    _showInfoSnackBar('Delete account feature coming soon!');
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
