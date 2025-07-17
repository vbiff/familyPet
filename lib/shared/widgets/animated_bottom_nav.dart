import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: AppTheme.smoothCurve,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.mediumShadow,
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return _AnimatedNavItem(
              item: item,
              isSelected: isSelected,
              onTap: () => widget.onTap(index),
              animationDelay: index * 50,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _scaleController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: AppTheme.bounceIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.smoothCurve,
    ));

    // Delayed entrance animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _bounceController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) {
              _scaleController.reverse();
              widget.onTap();
            },
            onTapCancel: () => _scaleController.reverse(),
            child: AnimatedContainer(
              duration: AppTheme.normalAnimation,
              curve: AppTheme.smoothCurve,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [
                          widget.item.color,
                          widget.item.color.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: widget.isSelected ? AppTheme.softShadow : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with bounce animation
                  Transform.scale(
                    scale: widget.isSelected
                        ? 0.8 + (0.4 * _bounceAnimation.value)
                        : 1.0,
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      color: widget.isSelected
                          ? Colors.white
                          : widget.item.color.withOpacity(0.6),
                      size: 24,
                    ).animate(
                      effects: widget.isSelected
                          ? [
                              const ScaleEffect(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.elasticOut,
                              ),
                              const ShimmerEffect(
                                duration: Duration(milliseconds: 800),
                                color: Colors.white,
                              ),
                            ]
                          : [],
                    ),
                  ),

                  // Animated label
                  AnimatedSize(
                    duration: AppTheme.normalAnimation,
                    curve: AppTheme.smoothCurve,
                    child: widget.isSelected
                        ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Text(
                              widget.item.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            )
                                .animate()
                                .slideX(
                                    begin: 0.5,
                                    duration: AppTheme.normalAnimation)
                                .fadeIn(duration: AppTheme.normalAnimation),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

class FloatingActionButtonAnimated extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final String? heroTag;

  const FloatingActionButtonAnimated({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.heroTag,
  });

  @override
  State<FloatingActionButtonAnimated> createState() =>
      _FloatingActionButtonAnimatedState();
}

class _FloatingActionButtonAnimatedState
    extends State<FloatingActionButtonAnimated> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppTheme.smoothCurve,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: AppTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: () {
                _scaleController.forward().then((_) {
                  _scaleController.reverse();
                  _rotationController.forward().then((_) {
                    _rotationController.reverse();
                  });
                });
                widget.onPressed();
              },
              backgroundColor: widget.backgroundColor ?? AppTheme.secondary,
              heroTag: widget.heroTag,
              child: widget.child,
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: const Duration(seconds: 3),
                  color: Colors.white.withOpacity(0.3),
                ),
          ),
        );
      },
    );
  }
}
