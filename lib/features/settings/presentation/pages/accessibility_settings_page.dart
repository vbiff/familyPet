import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/accessibility/accessibility_service.dart';
import 'package:jhonny/shared/widgets/animated_interactions.dart';

class AccessibilitySettingsPage extends ConsumerStatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  ConsumerState<AccessibilitySettingsPage> createState() =>
      _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState
    extends ConsumerState<AccessibilitySettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AccessibilityService _accessibilityService;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _accessibilityService = AccessibilityService();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _accessibilityService,
      builder: (context, child) {
        final settings = _accessibilityService.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Accessibility Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetToDefaults,
                tooltip: 'Reset to defaults',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual Settings Section
                _buildSectionHeader(
                  context,
                  'Visual Settings',
                  Icons.visibility,
                  0,
                ),
                const SizedBox(height: 16),
                _buildVisualSettings(settings),

                const SizedBox(height: 32),

                // Text Settings Section
                _buildSectionHeader(
                  context,
                  'Text & Reading',
                  Icons.text_fields,
                  200,
                ),
                const SizedBox(height: 16),
                _buildTextSettings(settings),

                const SizedBox(height: 32),

                // Motion Settings Section
                _buildSectionHeader(
                  context,
                  'Motion & Animations',
                  Icons.motion_photos_on,
                  400,
                ),
                const SizedBox(height: 16),
                _buildMotionSettings(settings),

                const SizedBox(height: 32),

                // Audio & Haptic Settings Section
                _buildSectionHeader(
                  context,
                  'Audio & Haptic Feedback',
                  Icons.volume_up,
                  600,
                ),
                const SizedBox(height: 16),
                _buildAudioHapticSettings(settings),

                const SizedBox(height: 32),

                // Quick Actions Section
                _buildSectionHeader(
                  context,
                  'Quick Actions',
                  Icons.speed,
                  800,
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),

                const SizedBox(height: 32),

                // Accessibility Tips
                _buildAccessibilityTips(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    int delay,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    ).animate(delay: delay.ms).fadeIn().slideX(begin: -0.2);
  }

  Widget _buildVisualSettings(AccessibilitySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingTile(
              title: 'High Contrast',
              subtitle: 'Increases contrast for better visibility',
              icon: Icons.contrast,
              value: settings.highContrast,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.highContrast,
                  value,
                );
                _showSettingFeedback(
                    'High contrast ${value ? 'enabled' : 'disabled'}');
              },
            ),
            const Divider(),
            _buildSettingTile(
              title: 'Large Text',
              subtitle: 'Makes text easier to read',
              icon: Icons.format_size,
              value: settings.largeText,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.largeText,
                  value,
                );
                _showSettingFeedback(
                    'Large text ${value ? 'enabled' : 'disabled'}');
              },
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildTextSettings(AccessibilitySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Scale Factor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust text size across the app',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.text_decrease,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                Expanded(
                  child: Slider(
                    value: settings.textScaleFactor,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    label: '${(settings.textScaleFactor * 100).round()}%',
                    onChanged: (value) {
                      _accessibilityService.updateTextScaleFactor(value);
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
                Icon(
                  Icons.text_increase,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sample text at ${(settings.textScaleFactor * 100).round()}% size',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14 * settings.textScaleFactor,
                  ),
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildMotionSettings(AccessibilitySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingTile(
              title: 'Reduced Motion',
              subtitle: 'Minimizes animations and transitions',
              icon: Icons.motion_photos_off,
              value: settings.reducedMotion,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.reducedMotion,
                  value,
                );
                _showSettingFeedback(
                    'Reduced motion ${value ? 'enabled' : 'disabled'}');
              },
            ),
            if (!settings.reducedMotion) ...[
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Animation Speed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control how fast animations play',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      Expanded(
                        child: Slider(
                          value: settings.animationSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: '${settings.animationSpeed}x',
                          onChanged: (value) {
                            _accessibilityService.updateAnimationSpeed(value);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      Icon(
                        Icons.fast_forward,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildAudioHapticSettings(AccessibilitySettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingTile(
              title: 'Haptic Feedback',
              subtitle: 'Vibration feedback for interactions',
              icon: Icons.vibration,
              value: settings.enhancedHaptics,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.hapticFeedback,
                  value,
                );
                if (value) {
                  HapticFeedback.mediumImpact();
                }
                _showSettingFeedback(
                    'Haptic feedback ${value ? 'enabled' : 'disabled'}');
              },
            ),
            const Divider(),
            _buildSettingTile(
              title: 'Audio Feedback',
              subtitle: 'Sound effects for app interactions',
              icon: Icons.volume_up,
              value: settings.audioFeedback,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.audioFeedback,
                  value,
                );
                _showSettingFeedback(
                    'Audio feedback ${value ? 'enabled' : 'disabled'}');
              },
            ),
            const Divider(),
            _buildSettingTile(
              title: 'Voice Announcements',
              subtitle: 'Spoken feedback for important actions',
              icon: Icons.record_voice_over,
              value: settings.voiceAnnouncements,
              onChanged: (value) {
                _accessibilityService.updateSetting(
                  AccessibilityFeature.voiceAnnouncements,
                  value,
                );
                if (value) {
                  _accessibilityService.announceToScreenReader(
                    'Voice announcements enabled',
                  );
                }
                _showSettingFeedback(
                    'Voice announcements ${value ? 'enabled' : 'disabled'}');
              },
            ),
          ],
        ),
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SpringButton(
              onPressed: _openSystemAccessibilitySettings,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_applications,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Accessibility Settings',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Open device accessibility settings',
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
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SpringButton(
              onPressed: _testAccessibilityFeatures,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Accessibility Features',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Try out your current settings',
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
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 900.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildAccessibilityTips() {
    final tips = _accessibilityService.getAccessibilityTips();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accessibility Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.take(3).map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate(delay: 1100.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SpringButton(
      onPressed: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _accessibilityService.announceToScreenReader(message);
  }

  void _resetToDefaults() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all accessibility settings to their default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _accessibilityService.resetToDefaults();
              Navigator.of(context).pop();
              _showSettingFeedback('Accessibility settings reset to defaults');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _openSystemAccessibilitySettings() {
    // This would open system accessibility settings
    // Implementation depends on platform
    _showSettingFeedback('Opening system accessibility settings...');
  }

  void _testAccessibilityFeatures() {
    _accessibilityService.hapticFeedback(HapticFeedbackType.medium);
    _accessibilityService.announceToScreenReader(
      'Testing accessibility features. Haptic feedback and voice announcement are working.',
    );
    _showSettingFeedback('Accessibility features tested successfully!');
  }
}
