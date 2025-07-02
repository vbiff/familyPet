import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jhonny/features/auth/presentation/pages/signup_page.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

class AppOnboardingPage extends ConsumerStatefulWidget {
  const AppOnboardingPage({super.key});

  @override
  ConsumerState<AppOnboardingPage> createState() => _AppOnboardingPageState();
}

class _AppOnboardingPageState extends ConsumerState<AppOnboardingPage>
    with TickerProviderStateMixin {
  PageController pageController = PageController();
  int currentPage = 0;
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingStep> onboardingSteps = [
    OnboardingStep(
      title: 'Welcome to Jhonny',
      description:
          'A fun family task manager where completing tasks helps your virtual pet grow and thrive!',
      lottieAsset: 'assets/animations/pet_idle.json',
      backgroundColor: const Color(0xFF6C63FF),
      icon: Icons.pets,
    ),
    OnboardingStep(
      title: 'Complete Family Tasks',
      description:
          'Assign tasks to family members and track progress together. Everyone contributes to pet care!',
      lottieAsset: 'assets/animations/pet_idle.json',
      backgroundColor: const Color(0xFF4ECDC4),
      icon: Icons.task_alt,
    ),
    OnboardingStep(
      title: 'Watch Your Pet Grow',
      description:
          'Your virtual pet evolves based on task completion. Keep your pet happy and healthy!',
      lottieAsset: 'assets/animations/pet_idle.json',
      backgroundColor: const Color(0xFFFF6B6B),
      icon: Icons.trending_up,
    ),
    OnboardingStep(
      title: 'Family Analytics',
      description:
          'Track family progress with beautiful charts and celebrate achievements together!',
      lottieAsset: 'assets/animations/pet_idle.json',
      backgroundColor: const Color(0xFF4ECDC4),
      icon: Icons.analytics,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    onboardingSteps[currentPage].backgroundColor,
                    onboardingSteps[currentPage]
                        .backgroundColor
                        .withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Skip button
            if (currentPage < onboardingSteps.length - 1)
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ),

            // Page content
            PageView.builder(
              controller: pageController,
              onPageChanged: _onPageChanged,
              itemCount: onboardingSteps.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(onboardingSteps[index]);
              },
            ),

            // Bottom navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 80),

          // Icon or Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: step.lottieAsset != null
                ? Lottie.asset(
                    step.lottieAsset!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        step.icon,
                        size: 60,
                        color: Colors.white,
                      );
                    },
                  )
                : Icon(
                    step.icon,
                    size: 60,
                    color: Colors.white,
                  ),
          ).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 60),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                step.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                step.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              // Back button
              if (currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToPreviousPage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ).animate().slideX(begin: -0.2).fadeIn(),
                )
              else
                const Expanded(child: SizedBox()),

              if (currentPage > 0) const SizedBox(width: 16),

              // Next/Get Started button
              Expanded(
                flex: currentPage == 0 ? 1 : 1,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        onboardingSteps[currentPage].backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    currentPage == onboardingSteps.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().slideX(begin: 0.2).fadeIn(),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingSteps.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      currentPage = page;
    });

    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  void _goToNextPage() {
    HapticFeedback.lightImpact();

    if (currentPage < onboardingSteps.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _goToPreviousPage() {
    HapticFeedback.lightImpact();

    if (currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skipOnboarding() async {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      // Navigate to signup/login
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SignupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final String? lottieAsset;
  final Color backgroundColor;
  final IconData icon;

  OnboardingStep({
    required this.title,
    required this.description,
    this.lottieAsset,
    required this.backgroundColor,
    required this.icon,
  });
}

// Provider to check if onboarding was completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});
