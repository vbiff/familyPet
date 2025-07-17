import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/features/auth/presentation/pages/login_page.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/home/presentation/pages/home_page.dart';
import 'package:jhonny/core/theme/app_theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppTheme.smoothCurve,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: AppTheme.slowAnimation,
          ),
          (route) => false,
        );
      } else if (next.status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppTheme.smoothCurve,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: AppTheme.slowAnimation,
          ),
          (route) => false,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.secondary,
              AppTheme.accent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Container
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseAnimation, _floatingAnimation]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 8),
                                blurRadius: 24,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Title
                Text(
                  'FamilyPet',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideY(
                        begin: 0.3,
                        duration: const Duration(milliseconds: 800)),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Where families grow together',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 800))
                    .slideY(
                        begin: 0.3,
                        duration: const Duration(milliseconds: 800)),

                const SizedBox(height: 60),

                // Loading Indicator
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .rotate(duration: const Duration(seconds: 2)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your family experience...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 1200))
                    .scale(delay: const Duration(milliseconds: 1200)),

                const SizedBox(height: 40),

                // Floating Elements
                _buildFloatingElements(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Stack(
        children: [
          // Floating hearts
          Positioned(
            left: 50,
            top: 20,
            child: Icon(
              Icons.favorite,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(begin: 0, end: -20, duration: const Duration(seconds: 3))
                .fadeIn(duration: const Duration(milliseconds: 500))
                .then()
                .fadeOut(duration: const Duration(milliseconds: 500)),
          ),

          Positioned(
            right: 60,
            top: 10,
            child: Icon(
              Icons.star,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(begin: 0, end: -15, duration: const Duration(seconds: 4))
                .fadeIn(duration: const Duration(milliseconds: 600))
                .then()
                .fadeOut(duration: const Duration(milliseconds: 600)),
          ),

          Positioned(
            left: 80,
            bottom: 20,
            child: Icon(
              Icons.child_care,
              color: Colors.white.withOpacity(0.2),
              size: 28,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(begin: 0, end: -25, duration: const Duration(seconds: 5))
                .fadeIn(duration: const Duration(milliseconds: 400))
                .then()
                .fadeOut(duration: const Duration(milliseconds: 400)),
          ),

          Positioned(
            right: 40,
            bottom: 30,
            child: Icon(
              Icons.family_restroom,
              color: Colors.white.withOpacity(0.3),
              size: 22,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(
                    begin: 0,
                    end: -18,
                    duration: const Duration(seconds: 3, milliseconds: 500))
                .fadeIn(duration: const Duration(milliseconds: 700))
                .then()
                .fadeOut(duration: const Duration(milliseconds: 700)),
          ),
        ],
      ),
    );
  }
}
