import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class AuthButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: AppTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: widget.isOutlined
            ? null
            : const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: widget.isOutlined ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: widget.isOutlined
            ? Border.all(color: AppTheme.primary, width: 2)
            : null,
        boxShadow: widget.isOutlined ? null : AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (widget.isLoading || widget.onPressed == null)
              ? null
              : () {
                  print('AuthButton onTap called');
                  widget.onPressed?.call();
                },
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          splashColor: widget.isOutlined
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
          highlightColor: widget.isOutlined
              ? AppTheme.primary.withOpacity(0.05)
              : Colors.white.withOpacity(0.1),
          child: Center(
            child: _buildChild(context),
          ),
        ),
      ),
    ).animate(
      effects: widget.isOutlined
          ? []
          : [
              ShimmerEffect(
                duration: const Duration(seconds: 3),
                color: Colors.white.withOpacity(0.2),
              ),
            ],
    );
  }

  Widget _buildChild(BuildContext context) {
    if (widget.isLoading) {
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
                widget.isOutlined ? AppTheme.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isOutlined ? AppTheme.primary : Colors.white,
                ),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: widget.isOutlined ? AppTheme.primary : Colors.white,
          ),
    )
        .animate()
        .fadeIn(duration: AppTheme.normalAnimation)
        .slideX(begin: 0.2, duration: AppTheme.normalAnimation);
  }
}
