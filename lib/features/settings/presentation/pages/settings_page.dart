import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/features/settings/presentation/widgets/language_selector.dart';
import 'package:jhonny/features/task/presentation/pages/archive_page.dart';
import 'package:jhonny/shared/widgets/delightful_button.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background,
              AppTheme.accent.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Section
              _buildSectionTitle('Language & Region', Icons.language),
              const SizedBox(height: 16),
              _buildAnimatedCard(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: LanguageSelector(),
                ),
                delay: 0,
              ),

              const SizedBox(height: 32),

              // App Settings Section
              _buildSectionTitle('App Settings', Icons.settings),
              const SizedBox(height: 16),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.archive_outlined,
                  title: 'Archived Tasks',
                  subtitle: 'View and manage archived tasks',
                  onTap: () async {
                    debugPrint('🔄 Settings: Navigating to Archive page');
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ArchivePage(),
                      ),
                    );
                    debugPrint('✅ Settings: Returned from Archive page');
                  },
                  color: AppTheme.orange,
                ),
                delay: 100,
              ),

              const SizedBox(height: 12),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.accessibility,
                  title: 'Accessibility',
                  subtitle: 'Customize accessibility features',
                  onTap: () {
                    // Navigate to accessibility settings
                    _showComingSoonDialog('Accessibility Settings');
                  },
                  color: AppTheme.accent,
                ),
                delay: 200,
              ),

              const SizedBox(height: 12),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    _showComingSoonDialog('Notification Settings');
                  },
                  color: AppTheme.secondary,
                ),
                delay: 300,
              ),

              const SizedBox(height: 12),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Theme & Appearance',
                  subtitle: 'Customize app colors and themes',
                  onTap: () {
                    _showComingSoonDialog('Theme Settings');
                  },
                  color: AppTheme.lavender,
                ),
                delay: 400,
              ),

              const SizedBox(height: 32),

              // Account Section
              _buildSectionTitle('Account', Icons.person_outline),
              const SizedBox(height: 16),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    _showComingSoonDialog('Privacy Settings');
                  },
                  color: AppTheme.green,
                ),
                delay: 500,
              ),

              const SizedBox(height: 12),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    _showComingSoonDialog('Help & Support');
                  },
                  color: AppTheme.blue,
                ),
                delay: 600,
              ),

              const SizedBox(height: 12),

              _buildAnimatedCard(
                child: _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'About FamilyPet',
                  subtitle: 'App version and information',
                  onTap: () {
                    _showAboutDialog();
                  },
                  color: AppTheme.primary,
                ),
                delay: 700,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        )
            .animate()
            .scale(delay: const Duration(milliseconds: 200))
            .then()
            .shimmer(duration: const Duration(seconds: 2)),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 100))
            .slideX(begin: 0.3, duration: AppTheme.normalAnimation),
      ],
    );
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.2, duration: AppTheme.normalAnimation)
        .then()
        .shimmer(
          delay: Duration(milliseconds: delay + 300),
          duration: const Duration(seconds: 2),
          color: AppTheme.primary.withOpacity(0.1),
        );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(
                Icons.construction,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Coming Soon!'),
          ],
        ),
        content: Text(
          '$featureName will be available in a future update. Stay tuned!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          DelightfulButton(
            text: 'Got it!',
            style: DelightfulButtonStyle.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ).animate().scale(curve: AppTheme.bounceIn).fadeIn(),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About FamilyPet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FamilyPet helps families grow together through fun tasks and a shared virtual pet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Made with ❤️ for families everywhere',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          DelightfulButton(
            text: 'Awesome!',
            style: DelightfulButtonStyle.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ).animate().scale(curve: AppTheme.bounceIn).fadeIn(),
    );
  }
}
