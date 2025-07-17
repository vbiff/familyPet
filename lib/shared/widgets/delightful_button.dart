import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class DelightfulButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DelightfulButtonStyle style;
  final bool isLoading;
  final double? width;

  const DelightfulButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style = DelightfulButtonStyle.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  State<DelightfulButton> createState() => _DelightfulButtonState();
}

class _DelightfulButtonState extends State<DelightfulButton>
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

    // Start shimmer animation
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForStyle(widget.style);

    return AnimatedBuilder(
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
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: widget.onPressed != null
                    ? [
                        BoxShadow(
                          color: colors.shadowColor,
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child:
                  widget.isLoading ? _buildLoadingState() : _buildNormalState(),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: const Duration(seconds: 3),
                  color: Colors.white.withOpacity(0.2),
                ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorsForStyle(widget.style).textColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Loading...',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _getColorsForStyle(widget.style).textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildNormalState() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: _getColorsForStyle(widget.style).textColor,
            size: 20,
          )
              .animate()
              .scale(delay: const Duration(milliseconds: 100))
              .then()
              .shake(duration: const Duration(milliseconds: 400)),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _getColorsForStyle(widget.style).textColor,
                fontWeight: FontWeight.w600,
              ),
        )
            .animate()
            .fadeIn(duration: AppTheme.normalAnimation)
            .slideX(begin: 0.2, duration: AppTheme.normalAnimation),
      ],
    );
  }

  _ButtonColors _getColorsForStyle(DelightfulButtonStyle style) {
    switch (style) {
      case DelightfulButtonStyle.primary:
        return _ButtonColors(
          gradientColors: [AppTheme.primary, AppTheme.secondary],
          textColor: Colors.white,
          shadowColor: AppTheme.primary.withOpacity(0.3),
        );
      case DelightfulButtonStyle.secondary:
        return _ButtonColors(
          gradientColors: [AppTheme.accent, AppTheme.blue],
          textColor: Colors.white,
          shadowColor: AppTheme.accent.withOpacity(0.3),
        );
      case DelightfulButtonStyle.success:
        return _ButtonColors(
          gradientColors: [AppTheme.success, AppTheme.success.withOpacity(0.8)],
          textColor: Colors.white,
          shadowColor: AppTheme.success.withOpacity(0.3),
        );
      case DelightfulButtonStyle.warning:
        return _ButtonColors(
          gradientColors: [AppTheme.warning, AppTheme.orange],
          textColor: Colors.white,
          shadowColor: AppTheme.warning.withOpacity(0.3),
        );
    }
  }
}

class _ButtonColors {
  final List<Color> gradientColors;
  final Color textColor;
  final Color shadowColor;

  _ButtonColors({
    required this.gradientColors,
    required this.textColor,
    required this.shadowColor,
  });
}

enum DelightfulButtonStyle {
  primary,
  secondary,
  success,
  warning,
}

class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final bool withRipple;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.withRipple = true,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.smoothCurve,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: AppTheme.bounceIn,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _bounceAnimation.value,
          child: Material(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: InkWell(
              onTap: widget.onPressed != null
                  ? () {
                      _scaleController.forward().then((_) {
                        _scaleController.reverse();
                        _bounceController.forward().then((_) {
                          _bounceController.reverse();
                        });
                      });
                      widget.onPressed?.call();
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              splashColor: widget.withRipple
                  ? (widget.color ?? AppTheme.primary).withOpacity(0.2)
                  : Colors.transparent,
              highlightColor: widget.withRipple
                  ? (widget.color ?? AppTheme.primary).withOpacity(0.1)
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: widget.color ?? AppTheme.primary,
                )
                    .animate()
                    .scale(duration: const Duration(milliseconds: 200))
                    .then()
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: Colors.white.withOpacity(0.3),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const BouncyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown:
                widget.onTap != null ? (_) => _controller.forward() : null,
            onTapUp: widget.onTap != null
                ? (_) {
                    _controller.reverse();
                    widget.onTap?.call();
                  }
                : null,
            onTapCancel: () => _controller.reverse(),
            child: Container(
              margin: widget.margin ?? const EdgeInsets.all(8),
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.softShadow,
              ),
              child: widget.child,
            )
                .animate()
                .fadeIn(duration: AppTheme.normalAnimation)
                .slideY(begin: 0.2, duration: AppTheme.normalAnimation),
          ),
        );
      },
    );
  }
}
