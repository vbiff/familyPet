import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

enum EnhancedButtonType {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

enum EnhancedButtonSize {
  small,
  medium,
  large,
}

class EnhancedButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final EnhancedButtonType type;
  final EnhancedButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const EnhancedButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.type = EnhancedButtonType.primary,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  }) : assert(text != null || child != null,
            'Either text or child must be provided');

  // Named constructors for different types
  const EnhancedButton.primary({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.primary,
        assert(text != null || child != null,
            'Either text or child must be provided');

  const EnhancedButton.secondary({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.secondary,
        assert(text != null || child != null,
            'Either text or child must be provided');

  const EnhancedButton.outline({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.outline,
        assert(text != null || child != null,
            'Either text or child must be provided');

  const EnhancedButton.ghost({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.ghost,
        assert(text != null || child != null,
            'Either text or child must be provided');

  const EnhancedButton.destructive({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.destructive,
        assert(text != null || child != null,
            'Either text or child must be provided');

  const EnhancedButton.link({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.size = EnhancedButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.gradient,
  })  : type = EnhancedButtonType.link,
        assert(text != null || child != null,
            'Either text or child must be provided');

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: AppTheme.smoothCurve,
    ));

    // Start shimmer for primary and secondary buttons
    if (widget.type == EnhancedButtonType.primary ||
        widget.type == EnhancedButtonType.secondary) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizeProps = _getSizeProperties();
    final typeStyle = _getTypeStyle();

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null
                ? (_) => _pressController.forward()
                : null,
            onTapUp: widget.onPressed != null
                ? (_) {
                    _pressController.reverse();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onPressed?.call();
                    });
                  }
                : null,
            onTapCancel: () => _pressController.reverse(),
            child: Container(
              constraints: BoxConstraints(minHeight: sizeProps.minHeight),
              decoration: BoxDecoration(
                gradient: widget.gradient ?? typeStyle.gradient,
                color: widget.gradient == null && typeStyle.gradient == null
                    ? (widget.backgroundColor ?? typeStyle.backgroundColor)
                    : null,
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(sizeProps.borderRadius),
                border: typeStyle.border,
                boxShadow: widget.shadows ?? typeStyle.boxShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(sizeProps.borderRadius),
                  splashColor:
                      (widget.foregroundColor ?? typeStyle.foregroundColor)
                          .withValues(alpha: 0.1),
                  highlightColor:
                      (widget.foregroundColor ?? typeStyle.foregroundColor)
                          .withValues(alpha: 0.05),
                  child: Container(
                    padding: sizeProps.padding,
                    child: _buildContent(),
                  ),
                ),
              ),
            ).animate(
              effects: (widget.type == EnhancedButtonType.primary ||
                      widget.type == EnhancedButtonType.secondary)
                  ? [
                      ShimmerEffect(
                        duration: const Duration(seconds: 3),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ]
                  : [],
            ),
          ),
        );
      },
    );

    if (widget.isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildContent() {
    final sizeProps = _getSizeProperties();
    final typeStyle = _getTypeStyle();

    if (widget.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: sizeProps.iconSize,
            width: sizeProps.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.foregroundColor ?? typeStyle.foregroundColor,
              ),
            ),
          ),
          if (widget.text != null || widget.child != null) ...[
            SizedBox(width: sizeProps.spacing),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: sizeProps.fontSize,
                fontWeight: sizeProps.fontWeight,
                color: widget.foregroundColor ?? typeStyle.foregroundColor,
              ),
            ),
          ],
        ],
      );
    }

    final children = <Widget>[];

    if (widget.leadingIcon != null) {
      children.add(Icon(
        widget.leadingIcon,
        size: sizeProps.iconSize,
        color: widget.foregroundColor ?? typeStyle.foregroundColor,
      )
          .animate()
          .scale(delay: const Duration(milliseconds: 100))
          .then()
          .shake(duration: const Duration(milliseconds: 200)));

      if (widget.text != null || widget.child != null) {
        children.add(SizedBox(width: sizeProps.spacing));
      }
    }

    if (widget.text != null) {
      children.add(Text(
        widget.text!,
        style: TextStyle(
          fontSize: sizeProps.fontSize,
          fontWeight: sizeProps.fontWeight,
          color: widget.foregroundColor ?? typeStyle.foregroundColor,
        ),
      )
          .animate()
          .fadeIn(duration: AppTheme.normalAnimation)
          .slideX(begin: 0.2, duration: AppTheme.normalAnimation));
    } else if (widget.child != null) {
      children.add(DefaultTextStyle(
        style: TextStyle(
          fontSize: sizeProps.fontSize,
          fontWeight: sizeProps.fontWeight,
          color: widget.foregroundColor ?? typeStyle.foregroundColor,
        ),
        child: widget.child!,
      ));
    }

    if (widget.trailingIcon != null) {
      if (widget.text != null || widget.child != null) {
        children.add(SizedBox(width: sizeProps.spacing));
      }
      children.add(Icon(
        widget.trailingIcon,
        size: sizeProps.iconSize,
        color: widget.foregroundColor ?? typeStyle.foregroundColor,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  _SizeProperties _getSizeProperties() {
    switch (widget.size) {
      case EnhancedButtonSize.small:
        return _SizeProperties(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fontSize: 12,
          iconSize: 16,
          minHeight: 36,
          spacing: 6,
          fontWeight: FontWeight.w600,
          borderRadius: AppTheme.radiusMedium,
        );
      case EnhancedButtonSize.medium:
        return _SizeProperties(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          fontSize: 14,
          iconSize: 18,
          minHeight: 44,
          spacing: 8,
          fontWeight: FontWeight.w600,
          borderRadius: AppTheme.radiusLarge,
        );
      case EnhancedButtonSize.large:
        return _SizeProperties(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          fontSize: 16,
          iconSize: 20,
          minHeight: 52,
          spacing: 10,
          fontWeight: FontWeight.w700,
          borderRadius: AppTheme.radiusXLarge,
        );
    }
  }

  _TypeStyle _getTypeStyle() {
    switch (widget.type) {
      case EnhancedButtonType.primary:
        return _TypeStyle(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
          boxShadow: AppTheme.softShadow,
        );
      case EnhancedButtonType.secondary:
        return _TypeStyle(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, AppTheme.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
          boxShadow: AppTheme.softShadow,
        );
      case EnhancedButtonType.outline:
        return _TypeStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primary,
          border: Border.all(color: AppTheme.primary, width: 2),
        );
      case EnhancedButtonType.ghost:
        return _TypeStyle(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          foregroundColor: AppTheme.primary,
        );
      case EnhancedButtonType.destructive:
        return _TypeStyle(
          gradient: LinearGradient(
            colors: [AppTheme.error, AppTheme.error.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        );
      case EnhancedButtonType.link:
        return _TypeStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primary,
        );
    }
  }
}

class _SizeProperties {
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double minHeight;
  final double spacing;
  final FontWeight fontWeight;
  final double borderRadius;

  _SizeProperties({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.minHeight,
    required this.spacing,
    required this.fontWeight,
    required this.borderRadius,
  });
}

class _TypeStyle {
  final Color? backgroundColor;
  final Color foregroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  _TypeStyle({
    this.backgroundColor,
    required this.foregroundColor,
    this.border,
    this.boxShadow,
    this.gradient,
  });
}
