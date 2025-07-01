import 'package:flutter/material.dart';

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

class EnhancedButton extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get size-specific properties
    final sizeProps = _getSizeProperties();

    // Get type-specific styling
    final typeStyle = _getTypeStyle(colorScheme);

    // Build the content
    Widget content = _buildContent(context);

    // Apply loading state
    if (isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: sizeProps.iconSize,
            height: sizeProps.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: typeStyle.foregroundColor,
            ),
          ),
          if (text != null || child != null) ...[
            SizedBox(width: sizeProps.spacing),
            if (text != null)
              Text('Loading...',
                  style: TextStyle(color: typeStyle.foregroundColor))
            else if (child != null)
              child!,
          ],
        ],
      );
    }

    // Create the button
    Widget button = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? typeStyle.backgroundColor)
            : null,
        gradient: gradient,
        borderRadius:
            borderRadius ?? BorderRadius.circular(sizeProps.borderRadius),
        border: typeStyle.border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius:
              borderRadius ?? BorderRadius.circular(sizeProps.borderRadius),
          child: Container(
            padding: sizeProps.padding,
            constraints: BoxConstraints(minHeight: sizeProps.minHeight),
            child: content,
          ),
        ),
      ),
    );

    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildContent(BuildContext context) {
    final sizeProps = _getSizeProperties();
    final typeStyle = _getTypeStyle(Theme.of(context).colorScheme);

    final children = <Widget>[];

    if (leadingIcon != null) {
      children.add(Icon(
        leadingIcon,
        size: sizeProps.iconSize,
        color: foregroundColor ?? typeStyle.foregroundColor,
      ));
      if (text != null || child != null) {
        children.add(SizedBox(width: sizeProps.spacing));
      }
    }

    if (text != null) {
      children.add(Text(
        text!,
        style: TextStyle(
          fontSize: sizeProps.fontSize,
          fontWeight: sizeProps.fontWeight,
          color: foregroundColor ?? typeStyle.foregroundColor,
        ),
      ));
    } else if (child != null) {
      children.add(DefaultTextStyle(
        style: TextStyle(
          fontSize: sizeProps.fontSize,
          fontWeight: sizeProps.fontWeight,
          color: foregroundColor ?? typeStyle.foregroundColor,
        ),
        child: child!,
      ));
    }

    if (trailingIcon != null) {
      if (text != null || child != null) {
        children.add(SizedBox(width: sizeProps.spacing));
      }
      children.add(Icon(
        trailingIcon,
        size: sizeProps.iconSize,
        color: foregroundColor ?? typeStyle.foregroundColor,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  _SizeProperties _getSizeProperties() {
    switch (size) {
      case EnhancedButtonSize.small:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          fontSize: 12,
          iconSize: 14,
          minHeight: 32,
          borderRadius: 6,
          spacing: 6,
          fontWeight: FontWeight.w500,
        );
      case EnhancedButtonSize.medium:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fontSize: 14,
          iconSize: 16,
          minHeight: 40,
          borderRadius: 8,
          spacing: 8,
          fontWeight: FontWeight.w500,
        );
      case EnhancedButtonSize.large:
        return const _SizeProperties(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          fontSize: 16,
          iconSize: 18,
          minHeight: 48,
          borderRadius: 10,
          spacing: 10,
          fontWeight: FontWeight.w600,
        );
    }
  }

  _TypeStyle _getTypeStyle(ColorScheme colorScheme) {
    switch (type) {
      case EnhancedButtonType.primary:
        return _TypeStyle(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          border: null,
        );
      case EnhancedButtonType.secondary:
        return _TypeStyle(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          border: null,
        );
      case EnhancedButtonType.outline:
        return _TypeStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          border: Border.all(color: colorScheme.outline),
        );
      case EnhancedButtonType.ghost:
        return _TypeStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          border: null,
        );
      case EnhancedButtonType.destructive:
        return _TypeStyle(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          border: null,
        );
      case EnhancedButtonType.link:
        return _TypeStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          border: null,
        );
    }
  }
}

class _SizeProperties {
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double minHeight;
  final double borderRadius;
  final double spacing;
  final FontWeight fontWeight;

  const _SizeProperties({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.minHeight,
    required this.borderRadius,
    required this.spacing,
    required this.fontWeight,
  });
}

class _TypeStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;

  const _TypeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
  });
}
