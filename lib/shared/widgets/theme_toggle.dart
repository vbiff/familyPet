import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/services/theme_service.dart' as theme_service;

class ThemeToggle extends StatefulWidget {
  final theme_service.ThemeService themeService;
  final Function(theme_service.ThemeMode)? onThemeChanged;

  const ThemeToggle({
    super.key,
    required this.themeService,
    this.onThemeChanged,
  });

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<theme_service.ThemeMode>(
      stream: widget.themeService.themeStream,
      initialData: widget.themeService.currentThemeMode,
      builder: (context, snapshot) {
        final currentTheme = snapshot.data ?? theme_service.ThemeMode.system;

        return PopupMenuButton<theme_service.ThemeMode>(
          onSelected: _handleThemeChange,
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            _buildThemeMenuItem(
              theme_service.ThemeMode.light,
              'Light Mode',
              Icons.light_mode,
              currentTheme,
            ),
            _buildThemeMenuItem(
              theme_service.ThemeMode.dark,
              'Dark Mode',
              Icons.dark_mode,
              currentTheme,
            ),
            _buildThemeMenuItem(
              theme_service.ThemeMode.system,
              'System',
              Icons.settings_brightness,
              currentTheme,
            ),
          ],
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getThemeIcon(currentTheme, context),
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getThemeLabel(currentTheme),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(
              begin: -0.2,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  PopupMenuItem<theme_service.ThemeMode> _buildThemeMenuItem(
    theme_service.ThemeMode themeMode,
    String label,
    IconData icon,
    theme_service.ThemeMode currentTheme,
  ) {
    final isSelected = currentTheme == themeMode;

    return PopupMenuItem<theme_service.ThemeMode>(
      value: themeMode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _handleThemeChange(theme_service.ThemeMode themeMode) async {
    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Change theme
    await widget.themeService.setThemeMode(themeMode);

    // Notify parent if callback provided
    widget.onThemeChanged?.call(themeMode);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getThemeIcon(themeMode, context),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Switched to ${_getThemeLabel(themeMode)}'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  IconData _getThemeIcon(
      theme_service.ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case theme_service.ThemeMode.light:
        return Icons.light_mode;
      case theme_service.ThemeMode.dark:
        return Icons.dark_mode;
      case theme_service.ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark
            ? Icons.dark_mode
            : Icons.light_mode;
    }
  }

  String _getThemeLabel(theme_service.ThemeMode themeMode) {
    switch (themeMode) {
      case theme_service.ThemeMode.light:
        return 'Light';
      case theme_service.ThemeMode.dark:
        return 'Dark';
      case theme_service.ThemeMode.system:
        return 'Auto';
    }
  }
}

// Simple theme switch for quick toggle
class SimpleThemeSwitch extends StatelessWidget {
  final theme_service.ThemeService themeService;
  final Function(bool)? onChanged;

  const SimpleThemeSwitch({
    super.key,
    required this.themeService,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<theme_service.ThemeMode>(
      stream: themeService.themeStream,
      initialData: themeService.currentThemeMode,
      builder: (context, snapshot) {
        final currentTheme = snapshot.data ?? theme_service.ThemeMode.system;
        final isDark = themeService.isDarkMode(context);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Switch.adaptive(
            key: ValueKey(isDark),
            value: isDark,
            onChanged: (value) {
              final newTheme = value
                  ? theme_service.ThemeMode.dark
                  : theme_service.ThemeMode.light;
              themeService.setThemeMode(newTheme);
              onChanged?.call(value);
            },
            thumbIcon: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.dark_mode, size: 16);
              }
              return const Icon(Icons.light_mode, size: 16);
            }),
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }
}

// Compact theme toggle button
class CompactThemeToggle extends StatelessWidget {
  final theme_service.ThemeService themeService;

  const CompactThemeToggle({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<theme_service.ThemeMode>(
      stream: themeService.themeStream,
      initialData: themeService.currentThemeMode,
      builder: (context, snapshot) {
        final isDark = themeService.isDarkMode(context);

        return IconButton(
          onPressed: () => themeService.toggleDarkMode(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: child,
              );
            },
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(isDark),
            ),
          ),
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        ).animate().scale(
              duration: 200.ms,
              curve: Curves.easeInOut,
            );
      },
    );
  }
}
