import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/shared/widgets/animated_interactions.dart';

class VirtualPet extends ConsumerWidget {
  const VirtualPet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petNotifierProvider);
    final familyState = ref.watch(familyNotifierProvider);
    final petMoodDisplay = ref.watch(petMoodDisplayProvider);
    final petStageDisplay = ref.watch(petStageDisplayProvider);
    final petAge = ref.watch(petAgeProvider);
    final petEvolutionStatus = ref.watch(petEvolutionStatusProvider);
    final currentUser = ref.watch(currentUserProvider);

    Color getFeedButtonColor(int? hunger) {
      if (hunger != null) {
        final percentage = (100 - hunger) / 100;
        if (percentage < 0.33) {
          return Colors.red;
        } else if (percentage < 0.66) {
          return Colors.orange;
        } else {
          return Colors.green;
        }
      } else {
        return Theme.of(context).colorScheme.primary;
      }
    }

    // Load pet data when family is available and valid
    ref.listen(familyNotifierProvider, (previous, next) {
      if (next.hasFamily &&
          next.family != null &&
          next.family!.id.isNotEmpty &&
          !petState.hasPet &&
          !petState.isLoading) {
        ref.read(petNotifierProvider.notifier).loadFamilyPet(next.family!.id);
      }
    });

    // Show action feedback
    ref.listen(petNotifierProvider, (previous, next) {
      // Only show snackbar if lastAction is new (different from previous state)
      if (next.lastAction != null &&
          (previous == null || previous.lastAction != next.lastAction)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastAction!),
            backgroundColor: next.hasEvolved
                ? Colors.purple
                : Theme.of(context).colorScheme.primary,
            duration: Duration(seconds: next.hasEvolved ? 4 : 2),
          ),
        );

        // Clear the action after a short delay to prevent immediate rebuilds from showing it again
        Future.delayed(const Duration(milliseconds: 100), () {
          ref.read(petNotifierProvider.notifier).clearLastAction();
        });
      }
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Virtual Pet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Show loading state
          if (petState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),

          // Show error state
          if (petState.hasError)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading pet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      petState.errorMessage ?? 'Unknown error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Show no pet state
          if (!petState.hasPet && !petState.isLoading && !petState.hasError)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Pet Yet',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete tasks to earn experience for your virtual pet!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    // Add Create Pet button
                    if (familyState.hasFamily)
                      ElevatedButton.icon(
                        onPressed: () =>
                            _createPet(context, ref, familyState.family!.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Pet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Show pet when available
          if (petState.hasPet) ...[
            // Pet status card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Pet avatar
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Display actual pet image based on mood
                          ClipOval(
                            child: _buildPetImage(
                              context,
                              familyState.family?.petImageUrl,
                              familyState.family?.petStageImages,
                              petState.petStage,
                              petState.currentMood,
                            ),
                          ),
                          if (petState.isUpdating)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      petState.petName,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            petStageDisplay,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            petMoodDisplay,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Level ${petState.petLevel} • ${petState.petExperience} XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),

                    // Show current mood and hunger status
                    if (petState.currentMood.isHungryState)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Pet needs feeding!',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 4),

                    Text(
                      petAge,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        petEvolutionStatus,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats section
            Text(
              'Pet Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.favorite,
                    label: 'Health',
                    value: petState.health,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.sentiment_very_satisfied,
                    label: 'Happiness',
                    value: petState.happiness,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.flash_on,
                    label: 'Energy',
                    value: petState.energy,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.restaurant,
                    label: 'Hunger',
                    value: petState.hunger,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.mood,
                    label: 'Emotion',
                    value: petState.emotion,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.school,
                    label: 'Experience',
                    value: petState.petExperience,
                    color: Colors.purple,
                    isExperience: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Text(
              'Pet Care',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Pet Actions
            if (petState.isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              _buildActionButton(
                context,
                icon: Icons.restaurant,
                label: petState.pet?.stats['hunger'] != null
                    ? 'Feed (${100 - petState.pet!.stats['hunger']!}%)'
                    : 'Feed Pet',
                color: getFeedButtonColor(petState.pet?.stats['hunger']),
                enabled: !petState.isUpdating,
                onTap: () {
                  ref.read(petNotifierProvider.notifier).feedPet();
                },
              ),

              const SizedBox(height: 12),

              SpringButton(
                onPressed: !petState.isUpdating
                    ? () {
                        ref.read(petNotifierProvider.notifier).playWithPet();
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PulsingIndicator(
                        child: Icon(
                          Icons.sports_esports,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Play with Pet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SpringButton(
                onPressed: !petState.isUpdating
                    ? () {
                        ref
                            .read(petNotifierProvider.notifier)
                            .giveMedicalCare();
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Medical Care',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Temporary reset button to fix happiness - only for parents
              if (currentUser?.role == UserRole.parent) ...[
                const SizedBox(height: 12),
                SpringButton(
                  onPressed: !petState.isUpdating
                      ? () {
                          ref
                              .read(petNotifierProvider.notifier)
                              .resetPetStats();
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reset Stats (Fix Happiness)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Pet Evolution Status with animation
            if (petEvolutionStatus.contains('evolve')) ...[
              SpringButton(
                onPressed: () {
                  // Handle evolution
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.purple,
                        Colors.deepPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      PulsingIndicator(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evolution Ready!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your pet is ready to evolve to the next stage',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ], // Close the conditional block for petState.hasPet
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool isExperience = false,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isExperience ? '$value XP' : '$value%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            if (!isExperience)
              LinearProgressIndicator(
                value: value / 100,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: enabled ? 0.1 : 0.05),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: enabled ? color : color.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? color : color.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetImage(
    BuildContext context,
    String? petImageUrl,
    Map<String, String>? petStageImages,
    PetStage stage,
    PetMood currentMood,
  ) {
    // Try to get mood-based image from Supabase storage first
    final moodImageUrl = _getMoodImageUrl(currentMood);

    // Use mood-based image if available, otherwise fall back to stage image
    String? imageUrl;
    if (moodImageUrl != null) {
      imageUrl = moodImageUrl;
    } else if (petStageImages != null) {
      imageUrl = petStageImages[stage.name];
    } else {
      imageUrl = petImageUrl;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local asset if network image fails
          return Image.asset(
            _getPetImagePath(stage),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Final fallback to icon if everything fails
              return Icon(
                Icons.pets,
                size: 90,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              );
            },
          );
        },
      );
    } else {
      // Use local asset as default
      return Image.asset(
        _getPetImagePath(stage),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            Icons.pets,
            size: 90,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          );
        },
      );
    }
  }

  String? _getMoodImageUrl(PetMood mood) {
    // TODO: Replace with your Supabase storage URL
    const baseUrl =
        'https://your-supabase-project.supabase.co/storage/v1/object/public/pet-images/';

    // Return the mood-based image URL
    return baseUrl + mood.imageName;
  }

  String _getPetImagePath(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return 'assets/images/pet_egg.png';
      case PetStage.baby:
        return 'assets/images/pet_baby.png';
      case PetStage.child:
        return 'assets/images/pet_child.png';
      case PetStage.teen:
        return 'assets/images/pet_teen.png';
      case PetStage.adult:
        return 'assets/images/pet_adult.png';
    }
  }

  Future<void> _createPet(
      BuildContext context, WidgetRef ref, String familyId) async {
    final nameController = TextEditingController();

    try {
      // Show dialog to name the pet
      final petName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Your Pet'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('What would you like to name your pet?'),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name',
                    hintText: 'Enter a name for your pet',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final name = value.trim();
                    Navigator.of(context).pop(name.isEmpty ? 'Fluffy' : name);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                Navigator.of(context).pop(name.isEmpty ? 'Fluffy' : name);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (petName != null && petName.isNotEmpty) {
        final currentUser = ref.read(currentUserProvider);
        await ref.read(petNotifierProvider.notifier).createPet(
              name: petName,
              familyId: familyId,
              ownerId: currentUser?.id,
            );
      }
    } finally {
      // Dispose controller in finally block to ensure it's always disposed
      nameController.dispose();
    }
  }
}
