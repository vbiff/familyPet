import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class AnimatedTaskCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCompleted;
  final int animationDelay;

  const AnimatedTaskCard({
    super.key,
    required this.child,
    this.onTap,
    this.isCompleted = false,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppTheme.normalAnimation,
      curve: AppTheme.bounceIn,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value > 1 ? 1 : value,
            child: _buildCard(context),
          ),
        );
      },
    )
        .animate(delay: Duration(milliseconds: animationDelay * 100))
        .slideY(begin: 0.3, curve: AppTheme.smoothCurve);
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  AppTheme.success.withOpacity(0.1),
                  AppTheme.success.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          splashColor: AppTheme.primary.withOpacity(0.1),
          highlightColor: AppTheme.primary.withOpacity(0.05),
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            curve: AppTheme.smoothCurve,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: isCompleted
                  ? Border.all(
                      color: AppTheme.success.withOpacity(0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PulsingTaskCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isUrgent;

  const PulsingTaskCard({
    super.key,
    required this.child,
    this.onTap,
    this.isUrgent = false,
  });

  @override
  State<PulsingTaskCard> createState() => _PulsingTaskCardState();
}

class _PulsingTaskCardState extends State<PulsingTaskCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isUrgent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isUrgent ? _pulseAnimation.value : 1.0,
          child: AnimatedTaskCard(
            onTap: widget.onTap,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class BouncyInteraction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const BouncyInteraction({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
  });

  @override
  State<BouncyInteraction> createState() => _BouncyInteractionState();
}

class _BouncyInteractionState extends State<BouncyInteraction>
    with TickerProviderStateMixin {
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
      end: widget.scaleDown,
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
