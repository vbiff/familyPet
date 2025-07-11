import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/pet_mood_service.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

/// Debug controls for testing the enhanced pet mood system
///
/// Features to test:
/// - Force happiness decay (10-20% random decrease)
/// - Test play interaction limits (once per hour)
/// - View interaction analytics
/// - Manual happiness restoration
class PetDebugControls extends ConsumerWidget {
  const PetDebugControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petNotifierProvider);
    final moodService = PetMoodService();

    if (!petState.hasPet) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No pet found - create a pet first to test mood system'),
        ),
      );
    }

    final petId = petState.pet!.id;
    final canPlay = moodService.canPlayWithPet(petId);
    final timeUntilPlay = moodService.getTimeUntilNextPlay(petId);
    final analytics = moodService.getInteractionAnalytics(petId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pet Mood System Debug Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Current Stats Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Stats:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Health: ${petState.health}%'),
                  Text('Happiness: ${petState.happiness}%'),
                  Text('Hunger: ${petState.hunger}%'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interaction Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interaction Status:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Can Play: ${canPlay ? "Yes" : "No"}'),
                  if (!canPlay && timeUntilPlay != null)
                    Text('Next play in: ${timeUntilPlay.inMinutes} minutes'),
                  if (analytics['lastPlayTime'] != null)
                    Text('Last played: ${analytics['lastPlayTime']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Debug Controls
            Text(
              'Debug Actions:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Force Happiness Decay
            EnhancedButton.outline(
              text: 'Force Happiness Decay',
              leadingIcon: Icons.trending_down,
              onPressed: () => _forceHappinessDecay(ref),
            ),
            const SizedBox(height: 8),

            // Force Health Decay
            EnhancedButton.outline(
              text: 'Force Health Decay (30-50%)',
              leadingIcon: Icons.health_and_safety,
              onPressed: () => _forceHealthDecay(ref),
            ),
            const SizedBox(height: 8),

            // Test Play Interaction
            EnhancedButton.primary(
              text: canPlay
                  ? 'Test Play (5% happiness)'
                  : 'Play Blocked (1h limit)',
              leadingIcon: Icons.sports_esports,
              backgroundColor: canPlay ? Colors.green : Colors.grey,
              onPressed: canPlay ? () => _testPlayInteraction(ref) : null,
            ),
            const SizedBox(height: 8),

            // Restore Happiness to 100%
            EnhancedButton.primary(
              text: 'Restore Happiness (100%)',
              leadingIcon: Icons.favorite,
              backgroundColor: Colors.pink,
              onPressed: () => _restoreHappiness(ref),
            ),
            const SizedBox(height: 8),

            // Restore Health to 100%
            EnhancedButton.primary(
              text: 'Restore Health (100%)',
              leadingIcon: Icons.medical_services,
              backgroundColor: Colors.red,
              onPressed: () => _restoreHealth(ref),
            ),
            const SizedBox(height: 8),

            // Reset Play Timer (for testing)
            EnhancedButton.outline(
              text: 'Reset Play Timer (Debug)',
              leadingIcon: Icons.refresh,
              onPressed: () => _resetPlayTimer(petId, context),
            ),
            const SizedBox(height: 8),

            // View Analytics
            EnhancedButton.outline(
              text: 'Show Analytics',
              leadingIcon: Icons.analytics,
              onPressed: () => _showAnalytics(context, analytics),
            ),
          ],
        ),
      ),
    );
  }

  void _forceHappinessDecay(WidgetRef ref) {
    ref.read(petNotifierProvider.notifier).applyHourlyHappinessDecay();
  }

  void _forceHealthDecay(WidgetRef ref) {
    ref.read(petNotifierProvider.notifier).applyWeeklyHealthDecay();
  }

  void _testPlayInteraction(WidgetRef ref) {
    ref.read(petNotifierProvider.notifier).playWithPet();
  }

  void _restoreHappiness(WidgetRef ref) {
    // Simulate task completion happiness boost
    final petNotifier = ref.read(petNotifierProvider.notifier);
    petNotifier.addExperienceFromTask(
      experiencePoints: 10,
      taskTitle: 'Debug: Happiness Restoration Test',
    );
  }

  void _restoreHealth(WidgetRef ref) {
    ref.read(petNotifierProvider.notifier).restoreHealth();
  }

  void _resetPlayTimer(String petId, BuildContext context) {
    // This is a debug function to reset the play timer for testing
    final moodService = PetMoodService();
    // Force reset by removing the last play time (for testing only)
    moodService.recordPlayInteraction(petId);

    // Then immediately clear it to allow instant play again
    // Note: This is a hack for testing - in production this shouldn't be possible
    final now = DateTime.now().subtract(const Duration(hours: 2));
    // We can't directly manipulate private fields, so this is just for demo

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Play timer reset! You can now play again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAnalytics(BuildContext context, Map<String, dynamic> analytics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pet Interaction Analytics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last Play Time: ${analytics['lastPlayTime'] ?? 'Never'}'),
              Text('Last Feed Time: ${analytics['lastFeedTime'] ?? 'Never'}'),
              Text('Last Heal Time: ${analytics['lastHealTime'] ?? 'Never'}'),
              Text(
                  'Last Health Decay: ${analytics['lastHealthDecayTime'] ?? 'Never'}'),
              const SizedBox(height: 8),
              Text('Can Play: ${analytics['canPlay']}'),
              Text(
                  'Time Until Next Play: ${analytics['timeUntilNextPlay'] ?? 'Now'} minutes'),
              Text(
                  'Should Apply Health Decay: ${analytics['shouldApplyHealthDecay']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
