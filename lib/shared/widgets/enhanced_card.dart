import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

enum EnhancedCardType {
  primary,
  secondary,
  outline,
  elevated,
  filled,
}

class EnhancedCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final EnhancedCardType type;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;
  final Gradient? gradient;
  final double? elevation;
  final bool showShimmer;

  const EnhancedCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.type = EnhancedCardType.primary,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.shadows,
    this.border,
    this.gradient,
    this.elevation,
    this.showShimmer = true,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppTheme.smoothCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = _getCardStyle();

    Widget card = AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: widget.gradient ?? cardStyle.gradient,
              color: widget.gradient == null && cardStyle.gradient == null
                  ? (widget.backgroundColor ?? cardStyle.backgroundColor)
                  : null,
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(AppTheme.radiusLarge),
              border: widget.border ?? cardStyle.border,
              boxShadow: widget.shadows ??
                  [
                    ...AppTheme.softShadow,
                    if (widget.onTap != null)
                      BoxShadow(
                        color: AppTheme.primary.withValues(
                          alpha: 0.1 * _elevationAnimation.value / 8.0,
                        ),
                        offset: Offset(0, _elevationAnimation.value),
                        blurRadius: _elevationAnimation.value * 2,
                      ),
                  ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(AppTheme.radiusLarge),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: widget.onTap != null
                    ? (_) => _hoverController.forward()
                    : null,
                onTapUp: widget.onTap != null
                    ? (_) => _hoverController.reverse()
                    : null,
                onTapCancel: () => _hoverController.reverse(),
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(AppTheme.radiusLarge),
                splashColor: AppTheme.primary.withValues(alpha: 0.1),
                highlightColor: AppTheme.primary.withValues(alpha: 0.05),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null ||
                          widget.titleWidget != null) ...[
                        widget.titleWidget ?? _buildTitle(),
                        const SizedBox(height: 16),
                      ],
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return card
        .animate()
        .fadeIn(duration: AppTheme.normalAnimation)
        .slideY(begin: 0.1, duration: AppTheme.normalAnimation);
  }

  Widget _buildTitle() {
    if (widget.title == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
      ],
    );
  }

  _CardStyle _getCardStyle() {
    switch (widget.type) {
      case EnhancedCardType.primary:
        return _CardStyle(
          backgroundColor: Colors.white,
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppTheme.primary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EnhancedCardType.secondary:
        return _CardStyle(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.05),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        );
      case EnhancedCardType.outline:
        return _CardStyle(
          backgroundColor: Colors.transparent,
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        );
      case EnhancedCardType.elevated:
        return _CardStyle(
          backgroundColor: Colors.white,
        );
      case EnhancedCardType.filled:
        return _CardStyle(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.1),
              AppTheme.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }
}

class _CardStyle {
  final Color? backgroundColor;
  final Border? border;
  final Gradient? gradient;

  _CardStyle({
    this.backgroundColor,
    this.border,
    this.gradient,
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
    return EnhancedCard(
      type: EnhancedCardType.outline,
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

    return EnhancedCard(
      type: EnhancedCardType.filled,
      backgroundColor: cardColor.withValues(alpha: 0.05),
      border: Border.all(color: cardColor.withValues(alpha: 0.2)),
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
