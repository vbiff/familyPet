import 'package:flutter/material.dart';
import 'package:jhonny/core/services/theme_service.dart' as theme_service;

// Theme toggle is disabled - only light theme available
class ThemeToggle extends StatelessWidget {
  final theme_service.ThemeService themeService;
  final Function(theme_service.ThemeMode)? onThemeChanged;

  const ThemeToggle({
    super.key,
    required this.themeService,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.light_mode,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Light Mode',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple theme switch for quick toggle - disabled
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.light_mode,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Light',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Compact theme toggle button - disabled
class CompactThemeToggle extends StatelessWidget {
  final theme_service.ThemeService themeService;

  const CompactThemeToggle({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: null, // Disabled
      icon: Icon(
        Icons.light_mode,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      ),
      tooltip: 'Light Mode Only',
    );
  }
}
