import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A button with spring animation and haptic feedback
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleDownFactor;
  final Duration duration;
  final bool enableHaptics;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  const SpringButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDownFactor = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptics = true,
    this.splashColor,
    this.borderRadius,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      if (widget.onPressed != null) {
        widget.onPressed!();
      }
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated counter with number transitions
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _previousValue = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: _previousValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _previousValue = widget.value;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_animation.value}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// Progress indicator with smooth animations
class AnimatedProgressIndicator extends StatefulWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;
  final bool showLabel;
  final String? label;

  const AnimatedProgressIndicator({
    super.key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 800),
    this.showLabel = false,
    this.label,
  });

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _animation.value,
              backgroundColor: widget.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progressColor ?? Theme.of(context).colorScheme.primary,
              ),
              minHeight: widget.height,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            );
          },
        ),
      ],
    );
  }
}

/// Floating action button with morphing animation
class MorphingFAB extends StatefulWidget {
  final List<FABItem> items;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onMainPressed;
  final IconData? mainIcon;

  const MorphingFAB({
    super.key,
    required this.items,
    this.backgroundColor,
    this.foregroundColor,
    this.onMainPressed,
    this.mainIcon,
  });

  @override
  State<MorphingFAB> createState() => _MorphingFABState();
}

class _MorphingFABState extends State<MorphingFAB>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.elasticOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Expanded items
        if (_isExpanded) ..._buildExpandedItems(),

        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 3.14159 * 2,
              child: FloatingActionButton(
                onPressed: widget.onMainPressed ?? _toggleExpanded,
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.foregroundColor,
                child: Icon(
                  _isExpanded ? Icons.close : (widget.mainIcon ?? Icons.add),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildExpandedItems() {
    return widget.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final delay = index * 50;

      return Positioned(
        bottom: 70.0 + (index * 60),
        right: 0,
        child: ScaleTransition(
          scale: _expandAnimation,
          child: FloatingActionButton.small(
            onPressed: () {
              item.onPressed();
              _toggleExpanded();
            },
            backgroundColor:
                item.backgroundColor ?? Theme.of(context).colorScheme.secondary,
            foregroundColor: item.foregroundColor ?? Colors.white,
            heroTag: "fab_$index",
            child: Icon(item.icon),
          ),
        ).animate(delay: delay.ms).slideY(begin: 0.5).fadeIn(),
      );
    }).toList();
  }
}

class FABItem {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  FABItem({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });
}

/// Pulsing indicator for notifications or status
class PulsingIndicator extends StatefulWidget {
  final Widget child;
  final Color? pulseColor;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingIndicator({
    super.key,
    required this.child,
    this.pulseColor,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.8,
    this.maxScale = 1.2,
  });

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Swipe to action widget
class SwipeToAction extends StatefulWidget {
  final Widget child;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final VoidCallback? onLeadingAction;
  final VoidCallback? onTrailingAction;
  final double threshold;
  final Color? leadingBackgroundColor;
  final Color? trailingBackgroundColor;

  const SwipeToAction({
    super.key,
    required this.child,
    this.leadingAction,
    this.trailingAction,
    this.onLeadingAction,
    this.onTrailingAction,
    this.threshold = 0.3,
    this.leadingBackgroundColor,
    this.trailingBackgroundColor,
  });

  @override
  State<SwipeToAction> createState() => _SwipeToActionState();
}

class _SwipeToActionState extends State<SwipeToAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  double _dragDistance = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragDistance += details.delta.dx;
      _dragDistance = _dragDistance.clamp(-200.0, 200.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * widget.threshold;

    if (_dragDistance.abs() > threshold) {
      // Trigger action
      if (_dragDistance > 0 && widget.onTrailingAction != null) {
        widget.onTrailingAction!();
        HapticFeedback.mediumImpact();
      } else if (_dragDistance < 0 && widget.onLeadingAction != null) {
        widget.onLeadingAction!();
        HapticFeedback.mediumImpact();
      }
    }

    // Reset position
    setState(() {
      _isDragging = false;
      _dragDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Background actions
          if (_dragDistance < 0 && widget.leadingAction != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _dragDistance.abs(),
              child: Container(
                color: widget.leadingBackgroundColor ?? Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: widget.leadingAction!,
              ),
            ),
          if (_dragDistance > 0 && widget.trailingAction != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _dragDistance,
              child: Container(
                color: widget.trailingBackgroundColor ?? Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: widget.trailingAction!,
              ),
            ),

          // Main content
          Transform.translate(
            offset: Offset(_dragDistance, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoader extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
