import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialType {
  home,
  petCare,
  taskCreation,
  familyManagement,
  analytics,
}

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final IconData? icon;
  final Color? color;
  final TutorialPosition position;
  final Duration? delay;

  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.icon,
    this.color,
    this.position = TutorialPosition.bottom,
    this.delay,
  });
}

enum TutorialPosition {
  top,
  bottom,
  left,
  right,
  center,
}

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  OverlayEntry? _overlayEntry;
  List<TutorialStep> _currentSteps = [];
  int _currentStepIndex = 0;
  VoidCallback? _onComplete;

  /// Show tutorial overlay for specific feature
  Future<void> showTutorial({
    required BuildContext context,
    required TutorialType type,
    VoidCallback? onComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialKey = 'tutorial_${type.name}_completed';

    if (prefs.getBool(tutorialKey) == true) {
      return; // Tutorial already completed
    }

    _onComplete = onComplete;
    _currentSteps = _getTutorialSteps(type);
    _currentStepIndex = 0;

    if (_currentSteps.isNotEmpty) {
      _showOverlay(context);
    }
  }

  /// Force show tutorial (ignore completion status)
  void showTutorialForced({
    required BuildContext context,
    required TutorialType type,
    VoidCallback? onComplete,
  }) {
    _onComplete = onComplete;
    _currentSteps = _getTutorialSteps(type);
    _currentStepIndex = 0;

    if (_currentSteps.isNotEmpty) {
      _showOverlay(context);
    }
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: _currentSteps,
        currentIndex: _currentStepIndex,
        onNext: _nextStep,
        onPrevious: _previousStep,
        onSkip: _skipTutorial,
        onComplete: _completeTutorial,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _nextStep() {
    HapticFeedback.lightImpact();

    if (_currentStepIndex < _currentSteps.length - 1) {
      _currentStepIndex++;
      _overlayEntry?.markNeedsBuild();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();

    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _skipTutorial() {
    HapticFeedback.lightImpact();
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Mark tutorial as completed
    if (_currentSteps.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      // You would need to pass the tutorial type to mark it as completed
      // For now, we'll just call the completion callback
    }

    _onComplete?.call();
    _currentSteps.clear();
    _currentStepIndex = 0;
  }

  /// Check if a specific tutorial has been completed
  static Future<bool> isTutorialCompleted(TutorialType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_${type.name}_completed') ?? false;
  }

  /// Mark a tutorial as completed
  static Future<void> markTutorialCompleted(TutorialType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_${type.name}_completed', true);
  }

  /// Reset all tutorials
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in TutorialType.values) {
      await prefs.remove('tutorial_${type.name}_completed');
    }
  }

  List<TutorialStep> _getTutorialSteps(TutorialType type) {
    switch (type) {
      case TutorialType.home:
        return _getHomeTutorialSteps();
      case TutorialType.petCare:
        return _getPetCareTutorialSteps();
      case TutorialType.taskCreation:
        return _getTaskCreationTutorialSteps();
      case TutorialType.familyManagement:
        return _getFamilyManagementTutorialSteps();
      case TutorialType.analytics:
        return _getAnalyticsTutorialSteps();
    }
  }

  List<TutorialStep> _getHomeTutorialSteps() {
    return [
      TutorialStep(
        title: 'Welcome to Jhonny!',
        description:
            'This is your family dashboard where you can see tasks, pet status, and family progress.',
        targetKey: GlobalKey(), // You would pass actual keys from widgets
        icon: Icons.home,
        color: Colors.blue,
        position: TutorialPosition.center,
      ),
      TutorialStep(
        title: 'Navigation Tabs',
        description:
            'Use these tabs to switch between Tasks, Pet Care, and Family sections.',
        targetKey: GlobalKey(),
        icon: Icons.navigation,
        color: Colors.green,
        position: TutorialPosition.bottom,
      ),
      TutorialStep(
        title: 'Quick Stats',
        description:
            'See your family\'s daily progress and pet happiness at a glance.',
        targetKey: GlobalKey(),
        icon: Icons.analytics,
        color: Colors.purple,
        position: TutorialPosition.top,
      ),
    ];
  }

  List<TutorialStep> _getPetCareTutorialSteps() {
    return [
      TutorialStep(
        title: 'Your Virtual Pet',
        description:
            'This is your family pet! Completing tasks keeps it happy and healthy.',
        targetKey: GlobalKey(),
        icon: Icons.pets,
        color: Colors.orange,
        position: TutorialPosition.bottom,
      ),
      TutorialStep(
        title: 'Pet Stats',
        description:
            'Monitor hunger and happiness levels. Complete tasks to improve these stats!',
        targetKey: GlobalKey(),
        icon: Icons.favorite,
        color: Colors.red,
        position: TutorialPosition.top,
      ),
      TutorialStep(
        title: 'Pet Actions',
        description:
            'Feed your pet using task points, play with it, or give medical care when needed.',
        targetKey: GlobalKey(),
        icon: Icons.touch_app,
        color: Colors.blue,
        position: TutorialPosition.top,
      ),
    ];
  }

  List<TutorialStep> _getTaskCreationTutorialSteps() {
    return [
      TutorialStep(
        title: 'Create New Task',
        description: 'Tap here to create a new task for family members.',
        targetKey: GlobalKey(),
        icon: Icons.add_task,
        color: Colors.green,
        position: TutorialPosition.left,
      ),
      TutorialStep(
        title: 'Task Details',
        description:
            'Fill in task name, description, assign to family members, and set point values.',
        targetKey: GlobalKey(),
        icon: Icons.edit,
        color: Colors.blue,
        position: TutorialPosition.center,
      ),
      TutorialStep(
        title: 'Task Categories',
        description:
            'Choose appropriate categories and difficulty levels for fair point distribution.',
        targetKey: GlobalKey(),
        icon: Icons.category,
        color: Colors.purple,
        position: TutorialPosition.bottom,
      ),
    ];
  }

  List<TutorialStep> _getFamilyManagementTutorialSteps() {
    return [
      TutorialStep(
        title: 'Family Members',
        description: 'Here you can see all family members and their progress.',
        targetKey: GlobalKey(),
        icon: Icons.family_restroom,
        color: Colors.teal,
        position: TutorialPosition.top,
      ),
      TutorialStep(
        title: 'Member Roles',
        description:
            'Parents can create tasks and manage settings, while children can complete tasks.',
        targetKey: GlobalKey(),
        icon: Icons.admin_panel_settings,
        color: Colors.orange,
        position: TutorialPosition.bottom,
      ),
      TutorialStep(
        title: 'Invite Members',
        description:
            'Tap here to invite new family members to join your Jhonny family.',
        targetKey: GlobalKey(),
        icon: Icons.person_add,
        color: Colors.green,
        position: TutorialPosition.left,
      ),
    ];
  }

  List<TutorialStep> _getAnalyticsTutorialSteps() {
    return [
      TutorialStep(
        title: 'Family Analytics',
        description:
            'Track your family\'s task completion trends and progress over time.',
        targetKey: GlobalKey(),
        icon: Icons.trending_up,
        color: Colors.blue,
        position: TutorialPosition.center,
      ),
      TutorialStep(
        title: 'Completion Charts',
        description:
            'Visual charts show daily, weekly, and monthly family progress.',
        targetKey: GlobalKey(),
        icon: Icons.bar_chart,
        color: Colors.green,
        position: TutorialPosition.bottom,
      ),
      TutorialStep(
        title: 'Member Leaderboard',
        description:
            'See which family members are most active and celebrate their achievements!',
        targetKey: GlobalKey(),
        icon: Icons.leaderboard,
        color: Colors.yellow,
        position: TutorialPosition.top,
      ),
    ];
  }
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fadeController.forward();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[widget.currentIndex];

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: GestureDetector(
        onTap: widget.onNext,
        child: Stack(
          children: [
            // Semi-transparent background
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),

            // Tutorial content
            _buildTutorialContent(currentStep),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IconButton(
                  onPressed: widget.onSkip,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ).animate().scale(delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialContent(TutorialStep step) {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and title
                Row(
                  children: [
                    if (step.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (step.color ?? Colors.blue)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          step.icon!,
                          color: step.color ?? Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Progress indicator
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(
                          widget.steps.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: index == widget.currentIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == widget.currentIndex
                                  ? (step.color ?? Colors.blue)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${widget.currentIndex + 1} of ${widget.steps.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Navigation buttons
                Row(
                  children: [
                    // Previous button
                    if (widget.currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onPrevious,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Previous'),
                        ),
                      )
                    else
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onSkip,
                          child: const Text('Skip'),
                        ),
                      ),

                    const SizedBox(width: 12),

                    // Next button
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            widget.currentIndex == widget.steps.length - 1
                                ? widget.onComplete
                                : widget.onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color ?? Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.currentIndex == widget.steps.length - 1
                              ? 'Got it!'
                              : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
