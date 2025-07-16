import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConfettiAnimation extends StatefulWidget {
  final Widget child;
  final bool show;
  final VoidCallback? onComplete;
  final Duration duration;

  const ConfettiAnimation({
    super.key,
    required this.child,
    required this.show,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation> {
  final Random _random = Random();
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _generateParticles();
  }

  void _generateParticles() {
    _particles = List.generate(
        50,
        (index) => ConfettiParticle(
              color: _getRandomColor(),
              startX: _random.nextDouble(),
              startY: -0.1,
              endX: _random.nextDouble(),
              endY: 1.1,
              rotation: _random.nextDouble() * 2 * pi,
              size: _random.nextDouble() * 8 + 4,
              delay: Duration(milliseconds: _random.nextInt(500)),
            ));
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(_particles),
              )
                  .animate()
                  .fadeIn(duration: 100.ms)
                  .then(delay: widget.duration)
                  .fadeOut(duration: 500.ms)
                  .callback(callback: (_) => widget.onComplete?.call()),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double size;
  final Duration delay;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.size,
    required this.delay,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width +
          (particle.endX - particle.startX) * size.width * 0.3;
      final y = particle.startY * size.height +
          (particle.endY - particle.startY) * size.height * 0.8;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation);

      // Draw confetti pieces as small rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Overlay widget for showing confetti across the entire screen
class ConfettiOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onComplete,
  }) {
    // Remove any existing overlay
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => ConfettiScreen(
        duration: duration,
        onComplete: () {
          hide();
          onComplete?.call();
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class ConfettiScreen extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiScreen({
    super.key,
    required this.duration,
    this.onComplete,
  });

  @override
  State<ConfettiScreen> createState() => _ConfettiScreenState();
}

class _ConfettiScreenState extends State<ConfettiScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<AnimatedConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _generateAnimatedParticles();
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  void _generateAnimatedParticles() {
    _particles = List.generate(
        80,
        (index) => AnimatedConfettiParticle(
              color: _getRandomColor(),
              startX: _random.nextDouble(),
              startY: -0.1,
              endX: _random.nextDouble() * 0.4 + 0.3,
              endY: 1.2,
              rotation: _random.nextDouble() * 4 * pi,
              size: _random.nextDouble() * 12 + 6,
              gravity: _random.nextDouble() * 0.3 + 0.7,
            ));
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.yellow.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.cyan.shade400,
      Colors.amber.shade400,
      Colors.lime.shade400,
      Colors.indigo.shade400,
      Colors.teal.shade400,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: AnimatedConfettiPainter(_particles, _controller.value),
              size: MediaQuery.of(context).size,
            );
          },
        ),
      ),
    );
  }
}

class AnimatedConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double size;
  final double gravity;

  AnimatedConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.size,
    required this.gravity,
  });
}

class AnimatedConfettiPainter extends CustomPainter {
  final List<AnimatedConfettiParticle> particles;
  final double progress;

  AnimatedConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.3)
        ..style = PaintingStyle.fill;

      // Apply gravity and movement
      final easedProgress = Curves.easeOut.transform(progress);
      final gravityProgress = easedProgress * easedProgress * particle.gravity;

      final x = particle.startX * size.width +
          (particle.endX - particle.startX) * size.width * easedProgress;
      final y =
          particle.startY * size.height + gravityProgress * size.height * 1.3;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress);

      // Draw confetti pieces with varying shapes
      final random = Random(particle.hashCode);
      if (random.nextBool()) {
        // Rectangle confetti
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        // Circle confetti
        canvas.drawCircle(
          Offset.zero,
          particle.size * 0.4,
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
