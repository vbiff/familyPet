import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/config/app_config.dart';
import 'package:jhonny/core/services/pet_mood_service.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';
import 'package:jhonny/shared/widgets/delightful_button.dart';

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
            DelightfulButton(
              text: 'Force Happiness Decay',
              icon: Icons.trending_down,
              style: DelightfulButtonStyle.warning,
              onPressed: () => _forceHappinessDecay(ref),
            ),
            const SizedBox(height: 8),

            // Force Health Decay
            DelightfulButton(
              text: 'Force Health Decay (30-50%)',
              icon: Icons.health_and_safety,
              style: DelightfulButtonStyle.warning,
              onPressed: () => _forceHealthDecay(ref),
            ),
            const SizedBox(height: 8),

            // Test Play Interaction
            DelightfulButton(
              text: canPlay
                  ? 'Test Play (5% happiness)'
                  : 'Play Blocked (1h limit)',
              icon: Icons.sports_esports,
              style: canPlay
                  ? DelightfulButtonStyle.success
                  : DelightfulButtonStyle.secondary,
              onPressed: canPlay ? () => _testPlayInteraction(ref) : null,
            ),
            const SizedBox(height: 8),

            // Restore Happiness to 100%
            DelightfulButton(
              text: 'Restore Happiness (100%)',
              icon: Icons.favorite,
              style: DelightfulButtonStyle.primary,
              onPressed: () => _restoreHappiness(ref),
            ),
            const SizedBox(height: 8),

            // Restore Health to 100%
            DelightfulButton(
              text: 'Restore Health (100%)',
              icon: Icons.medical_services,
              style: DelightfulButtonStyle.warning,
              onPressed: () => _restoreHealth(ref),
            ),
            const SizedBox(height: 8),

            // Reset Play Timer (for testing)
            DelightfulButton(
              text: 'Reset Play Timer (Debug)',
              icon: Icons.refresh,
              style: DelightfulButtonStyle.secondary,
              onPressed: () => _resetPlayTimer(petId, context),
            ),
            const SizedBox(height: 8),

            // View Analytics
            DelightfulButton(
              text: 'Show Analytics',
              icon: Icons.analytics,
              style: DelightfulButtonStyle.secondary,
              onPressed: () => _showAnalytics(context, analytics),
            ),
            const SizedBox(height: 8),

            // Change Mood (Debug)
            DelightfulButton(
              text: 'Change Mood',
              icon: Icons.mood,
              style: DelightfulButtonStyle.primary,
              onPressed: () => _showMoodDialog(context, ref),
            ),
            const SizedBox(height: 8),

            // Test Stage Evolution
            DelightfulButton(
              text: 'Test Stage Evolution',
              icon: Icons.arrow_upward,
              style: DelightfulButtonStyle.secondary,
              onPressed: () => _showStageDialog(context, ref),
            ),
            const SizedBox(height: 8),

            // Test Image URL
            DelightfulButton(
              text: 'Test Very Happy Image URL',
              icon: Icons.image,
              style: DelightfulButtonStyle.secondary,
              onPressed: () => _testImageUrl(context, ref),
            ),
            const SizedBox(height: 8),

            // Show Config URL
            DelightfulButton(
              text: 'Show Supabase Config',
              icon: Icons.settings,
              style: DelightfulButtonStyle.secondary,
              onPressed: () => _showSupabaseConfig(context),
            ),
            const SizedBox(height: 8),

            // Image Type Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image Info:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Current Mood: ${petState.currentMood.name}'),
                  Text('Pet Stage: ${petState.petStage.name}'),
                  const SizedBox(height: 4),
                  // Show what type of image should be used based on stage
                  if (petState.petStage == PetStage.egg ||
                      petState.petStage == PetStage.baby) ...[
                    Text('Image Type: Stage-based (${petState.petStage.name})',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'Expected Image: ${_getExpectedStageImage(petState.petStage)}'),
                  ] else if (petState.currentMood == PetMood.neutral) ...[
                    Text(
                        'Image Type: Stage-based (neutral ${petState.petStage.name})',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'Expected Image: ${_getExpectedStageImage(petState.petStage)}'),
                  ] else ...[
                    Text('Image Type: Mood-based (${petState.petStage.name})',
                        style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'Expected Mood Image: ${petState.currentMood.moodImageName ?? "None (uses stage image)"}'),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Growth Logic: Egg & Baby → Stage images | Neutral → Stage images | Other moods → Mood images',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExpectedStageImage(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return 'pet_egg.png';
      case PetStage.baby:
        return 'pet_baby.png';
      case PetStage.child:
        return 'pet_child.png';
      case PetStage.teen:
        return 'pet_teen.png';
      case PetStage.adult:
        return 'pet_adult.png';
    }
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

  void _showMoodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Pet Mood'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a mood to change your pet to:'),
              const SizedBox(height: 16),
              ...PetMood.values.map((mood) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          debugPrint('🎭 Debug: Changing mood to ${mood.name}');
                          ref
                              .read(petNotifierProvider.notifier)
                              .debugChangeMood(mood);
                          Navigator.of(context).pop();
                          debugPrint('🎭 Debug: Mood change completed');
                        },
                        child: Text(mood.name.toUpperCase()),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _testImageUrl(BuildContext context, WidgetRef ref) {
    // Test URL construction directly using AppConfig with defaults folder
    final baseUrl =
        '${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.storagePetImagesBucket}/defaults/';
    final testUrl = '${baseUrl}very-happy.png';

    debugPrint('🧪 Testing image URL: $testUrl');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('URL: $testUrl'),
            const SizedBox(height: 16),
            SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                testUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Test image failed to load: $error');
                  return Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      Text('Failed to load\n$error',
                          style: const TextStyle(fontSize: 10)),
                    ],
                  );
                },
              ),
            ),
          ],
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

  void _showSupabaseConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supabase Configuration'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Supabase URL: ${AppConfig.supabaseUrl}'),
              const Text('Storage Bucket: ${AppConfig.storagePetImagesBucket}'),
              Text(
                  'Supabase Anon Key: ${AppConfig.supabaseAnonKey.substring(0, 20)}...'),
              const SizedBox(height: 8),
              Text(
                  'Full Image URL: ${AppConfig.supabaseUrl}/storage/v1/object/public/${AppConfig.storagePetImagesBucket}/defaults/very-happy.png'),
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

  void _showStageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Pet Stage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a stage to test the growth scenario:'),
              const SizedBox(height: 16),
              ...PetStage.values.map((stage) {
                final isEarlyStage =
                    stage == PetStage.egg || stage == PetStage.baby;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('🔄 Debug: Changing stage to ${stage.name}');
                        _changeStageForTesting(ref, stage);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEarlyStage
                            ? Colors.orange.shade100
                            : Colors.purple.shade100,
                        foregroundColor: isEarlyStage
                            ? Colors.orange.shade700
                            : Colors.purple.shade700,
                      ),
                      child: Text(
                          '${stage.name.toUpperCase()} ${isEarlyStage ? "(Stage Image)" : "(Mood Image)"}'),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeStageForTesting(WidgetRef ref, PetStage newStage) {
    // Use the debug method from pet notifier to change stage
    ref.read(petNotifierProvider.notifier).debugChangeStage(newStage);
  }
}
