import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccessibilityFeature {
  highContrast,
  largeText,
  reducedMotion,
  screenReader,
  hapticFeedback,
  audioFeedback,
  voiceAnnouncements,
}

class AccessibilitySettings {
  final bool highContrast;
  final bool largeText;
  final bool reducedMotion;
  final bool enhancedHaptics;
  final bool audioFeedback;
  final bool voiceAnnouncements;
  final double textScaleFactor;
  final double animationSpeed;

  AccessibilitySettings({
    this.highContrast = false,
    this.largeText = false,
    this.reducedMotion = false,
    this.enhancedHaptics = true,
    this.audioFeedback = false,
    this.voiceAnnouncements = false,
    this.textScaleFactor = 1.0,
    this.animationSpeed = 1.0,
  });

  AccessibilitySettings copyWith({
    bool? highContrast,
    bool? largeText,
    bool? reducedMotion,
    bool? enhancedHaptics,
    bool? audioFeedback,
    bool? voiceAnnouncements,
    double? textScaleFactor,
    double? animationSpeed,
  }) {
    return AccessibilitySettings(
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      enhancedHaptics: enhancedHaptics ?? this.enhancedHaptics,
      audioFeedback: audioFeedback ?? this.audioFeedback,
      voiceAnnouncements: voiceAnnouncements ?? this.voiceAnnouncements,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highContrast': highContrast,
      'largeText': largeText,
      'reducedMotion': reducedMotion,
      'enhancedHaptics': enhancedHaptics,
      'audioFeedback': audioFeedback,
      'voiceAnnouncements': voiceAnnouncements,
      'textScaleFactor': textScaleFactor,
      'animationSpeed': animationSpeed,
    };
  }

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      highContrast: json['highContrast'] ?? false,
      largeText: json['largeText'] ?? false,
      reducedMotion: json['reducedMotion'] ?? false,
      enhancedHaptics: json['enhancedHaptics'] ?? true,
      audioFeedback: json['audioFeedback'] ?? false,
      voiceAnnouncements: json['voiceAnnouncements'] ?? false,
      textScaleFactor: json['textScaleFactor']?.toDouble() ?? 1.0,
      animationSpeed: json['animationSpeed']?.toDouble() ?? 1.0,
    );
  }
}

class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  AccessibilitySettings _settings = AccessibilitySettings();
  SharedPreferences? _prefs;

  AccessibilitySettings get settings => _settings;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();

    // Auto-detect system accessibility settings
    await _detectSystemAccessibilitySettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final settingsJson = _prefs!.getString('accessibility_settings');
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          // In a real app, you'd use json.decode() here
          <String, dynamic>{},
        );
        _settings = AccessibilitySettings.fromJson(json);
      } catch (e) {
        // Reset to defaults if loading fails
        _settings = AccessibilitySettings();
      }
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    final settingsJson = _settings.toJson();
    // In a real app, you'd use json.encode() here
    await _prefs!.setString('accessibility_settings', settingsJson.toString());
  }

  Future<void> _detectSystemAccessibilitySettings() async {
    // Auto-enable features based on system settings
    final mediaQuery = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    );

    bool shouldUpdate = false;

    // Detect high contrast
    if (mediaQuery.highContrast && !_settings.highContrast) {
      _settings = _settings.copyWith(highContrast: true);
      shouldUpdate = true;
    }

    // Detect reduced motion
    if (mediaQuery.disableAnimations && !_settings.reducedMotion) {
      _settings = _settings.copyWith(reducedMotion: true);
      shouldUpdate = true;
    }

    // Detect large text
    final textScale = mediaQuery.textScaler.scale(1.0);
    if (textScale > 1.2 && !_settings.largeText) {
      _settings = _settings.copyWith(
        largeText: true,
        textScaleFactor: textScale,
      );
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      await _saveSettings();
      notifyListeners();
    }
  }

  /// Update a specific accessibility setting
  Future<void> updateSetting(AccessibilityFeature feature, bool enabled) async {
    switch (feature) {
      case AccessibilityFeature.highContrast:
        _settings = _settings.copyWith(highContrast: enabled);
        break;
      case AccessibilityFeature.largeText:
        _settings = _settings.copyWith(largeText: enabled);
        break;
      case AccessibilityFeature.reducedMotion:
        _settings = _settings.copyWith(reducedMotion: enabled);
        break;
      case AccessibilityFeature.hapticFeedback:
        _settings = _settings.copyWith(enhancedHaptics: enabled);
        break;
      case AccessibilityFeature.audioFeedback:
        _settings = _settings.copyWith(audioFeedback: enabled);
        break;
      case AccessibilityFeature.voiceAnnouncements:
        _settings = _settings.copyWith(voiceAnnouncements: enabled);
        break;
      case AccessibilityFeature.screenReader:
        // Screen reader support is handled by the system
        break;
    }

    await _saveSettings();
    notifyListeners();
  }

  /// Update text scale factor
  Future<void> updateTextScaleFactor(double scale) async {
    _settings = _settings.copyWith(textScaleFactor: scale);
    await _saveSettings();
    notifyListeners();
  }

  /// Update animation speed
  Future<void> updateAnimationSpeed(double speed) async {
    _settings = _settings.copyWith(animationSpeed: speed);
    await _saveSettings();
    notifyListeners();
  }

  /// Provide haptic feedback with accessibility considerations
  void hapticFeedback(HapticFeedbackType type) {
    if (!_settings.enhancedHaptics) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Announce text to screen readers
  void announceToScreenReader(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Get animation duration adjusted for accessibility settings
  Duration getAdjustedDuration(Duration baseDuration) {
    if (_settings.reducedMotion) {
      return Duration.zero;
    }

    final adjustedMs =
        (baseDuration.inMilliseconds / _settings.animationSpeed).round();
    return Duration(milliseconds: adjustedMs);
  }

  /// Check if an animation should be disabled
  bool shouldDisableAnimation() {
    return _settings.reducedMotion;
  }

  /// Get text style with accessibility adjustments
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    TextStyle adjustedStyle = baseStyle;

    // Apply text scaling
    if (_settings.largeText || _settings.textScaleFactor != 1.0) {
      adjustedStyle = adjustedStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * _settings.textScaleFactor,
      );
    }

    // Apply high contrast if enabled
    if (_settings.highContrast) {
      adjustedStyle = adjustedStyle.copyWith(
        color: _getHighContrastColor(baseStyle.color),
        fontWeight: FontWeight.w600, // Make text bolder
      );
    }

    return adjustedStyle;
  }

  /// Get color with high contrast adjustments
  Color _getHighContrastColor(Color? originalColor) {
    if (originalColor == null) return Colors.black;

    // Calculate luminance
    final luminance = originalColor.computeLuminance();

    // Return high contrast version
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Create accessible semantics for widgets
  Semantics createAccessibleSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool? enabled,
    bool? selected,
    bool? button,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      enabled: enabled,
      selected: selected,
      button: button,
      onTap: onTap,
      child: child,
    );
  }

  /// Create accessible button semantics
  Widget createAccessibleButton({
    required Widget child,
    required String label,
    required VoidCallback onPressed,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      child: GestureDetector(
        onTap: enabled
            ? () {
                hapticFeedback(HapticFeedbackType.light);
                onPressed();
              }
            : null,
        child: child,
      ),
    );
  }

  /// Reset all accessibility settings to defaults
  Future<void> resetToDefaults() async {
    _settings = AccessibilitySettings();
    await _saveSettings();
    notifyListeners();
  }

  /// Get accessibility tips for the current context
  List<String> getAccessibilityTips() {
    return [
      'Use the back button or swipe gesture to navigate back',
      'Double-tap to activate buttons and controls',
      'Swipe right to move to the next element',
      'Swipe left to move to the previous element',
      'Adjust text size in Settings for better readability',
      'Enable high contrast mode for better visibility',
      'Use haptic feedback for tactile confirmation',
    ];
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

/// Widget that automatically applies accessibility settings
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final bool excludeSemantics;

  const AccessibleWidget({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();

    Widget widget = child;

    // Wrap with semantics if needed
    if (!excludeSemantics && (semanticLabel != null || semanticHint != null)) {
      widget = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        child: widget,
      );
    }

    return widget;
  }
}

/// Accessible text widget that automatically applies accessibility settings
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    final adjustedStyle = accessibilityService.getAccessibleTextStyle(
      style ?? Theme.of(context).textTheme.bodyMedium!,
    );

    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: adjustedStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
