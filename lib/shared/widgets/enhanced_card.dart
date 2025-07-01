import 'package:flutter/material.dart';

enum EnhancedCardType {
  elevated,
  outlined,
  filled,
  gradient,
}

class EnhancedCard extends StatelessWidget {
  final Widget? child;
  final String? title;
  final String? description;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets? padding;
  final EnhancedCardType type;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const EnhancedCard({
    super.key,
    this.child,
    this.title,
    this.description,
    this.header,
    this.footer,
    this.padding,
    this.type = EnhancedCardType.elevated,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.shadows,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  });

  // Named constructors for different types
  const EnhancedCard.elevated({
    super.key,
    this.child,
    this.title,
    this.description,
    this.header,
    this.footer,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.shadows,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  }) : type = EnhancedCardType.elevated;

  const EnhancedCard.outlined({
    super.key,
    this.child,
    this.title,
    this.description,
    this.header,
    this.footer,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.shadows,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  }) : type = EnhancedCardType.outlined;

  const EnhancedCard.filled({
    super.key,
    this.child,
    this.title,
    this.description,
    this.header,
    this.footer,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.shadows,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
  }) : type = EnhancedCardType.filled;

  const EnhancedCard.gradient({
    super.key,
    this.child,
    this.title,
    this.description,
    this.header,
    this.footer,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.shadows,
    required this.gradient,
    this.onTap,
    this.width,
    this.height,
  }) : type = EnhancedCardType.gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get type-specific styling
    final typeStyle = _getTypeStyle(colorScheme);

    // Build the content
    final content = _buildContent(context);

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? typeStyle.backgroundColor)
            : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: typeStyle.border,
        boxShadow: shadows ?? typeStyle.shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                child: content,
              )
            : content,
      ),
    );

    return card;
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPadding = padding ?? const EdgeInsets.all(16);

    final children = <Widget>[];

    // Add header if provided
    if (header != null) {
      children.add(header!);
      children.add(const SizedBox(height: 16));
    }

    // Add title and description
    if (title != null || description != null) {
      final titleDescColumn = <Widget>[];

      if (title != null) {
        titleDescColumn.add(
          Text(
            title!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      if (description != null) {
        if (title != null) {
          titleDescColumn.add(const SizedBox(height: 8));
        }
        titleDescColumn.add(
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      children.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: titleDescColumn,
      ));

      if (child != null) {
        children.add(const SizedBox(height: 16));
      }
    }

    // Add main content
    if (child != null) {
      children.add(child!);
    }

    // Add footer if provided
    if (footer != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(footer!);
    }

    return Padding(
      padding: defaultPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  _TypeStyle _getTypeStyle(ColorScheme colorScheme) {
    switch (type) {
      case EnhancedCardType.elevated:
        return _TypeStyle(
          backgroundColor: colorScheme.surface,
          border: null,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case EnhancedCardType.outlined:
        return _TypeStyle(
          backgroundColor: colorScheme.surface,
          border: Border.all(color: borderColor ?? colorScheme.outline),
          shadows: null,
        );
      case EnhancedCardType.filled:
        return _TypeStyle(
          backgroundColor: colorScheme.surfaceContainerLow,
          border: null,
          shadows: null,
        );
      case EnhancedCardType.gradient:
        return _TypeStyle(
          backgroundColor: null,
          border: null,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }
  }
}

class _TypeStyle {
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? shadows;

  const _TypeStyle({
    this.backgroundColor,
    this.border,
    this.shadows,
  });
}

// Specialized card variants
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard.outlined(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final List<Widget>? actions;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;

    return EnhancedCard.filled(
      backgroundColor: cardColor.withValues(alpha: 0.05),
      borderColor: cardColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: cardColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cardColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (actions != null) ...[
            const SizedBox(height: 16),
            Row(
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
