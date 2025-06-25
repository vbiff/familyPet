import 'package:test/test.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';

void main() {
  group('Pet Entity Tests', () {
    group('PetMood enum', () {
      test('should identify positive moods correctly', () {
        expect(PetMood.happy.isPositive, isTrue);
        expect(PetMood.content.isPositive, isTrue);
        expect(PetMood.neutral.isPositive, isFalse);
        expect(PetMood.sad.isPositive, isFalse);
        expect(PetMood.upset.isPositive, isFalse);
      });

      test('should identify negative moods correctly', () {
        expect(PetMood.sad.isNegative, isTrue);
        expect(PetMood.upset.isNegative, isTrue);
        expect(PetMood.happy.isNegative, isFalse);
        expect(PetMood.content.isNegative, isFalse);
        expect(PetMood.neutral.isNegative, isFalse);
      });
    });

    group('PetStage enum', () {
      test('should identify stages that can evolve', () {
        expect(PetStage.egg.canEvolve, isTrue);
        expect(PetStage.baby.canEvolve, isTrue);
        expect(PetStage.child.canEvolve, isTrue);
        expect(PetStage.teen.canEvolve, isTrue);
        expect(PetStage.adult.canEvolve, isFalse);
      });

      test('should return correct next stage', () {
        expect(PetStage.egg.nextStage, PetStage.baby);
        expect(PetStage.baby.nextStage, PetStage.child);
        expect(PetStage.child.nextStage, PetStage.teen);
        expect(PetStage.teen.nextStage, PetStage.adult);
        expect(PetStage.adult.nextStage, isNull);
      });
    });

    group('Pet class', () {
      late Pet testPet;
      late DateTime testDate;

      setUp(() {
        testDate = DateTime(2024, 1, 1, 12, 0, 0);
        testPet = Pet(
          id: 'pet-123',
          name: 'Fluffy',
          familyId: 'family-123',
          ownerId: 'child-1',
          stage: PetStage.child,
          mood: PetMood.happy,
          experience: 400,
          level: 5,
          currentImageUrl: 'https://example.com/fluffy.jpg',
          unlockedImageUrls: const ['img1.jpg', 'img2.jpg'],
          lastFedAt: testDate.subtract(const Duration(hours: 2)),
          lastPlayedAt: testDate.subtract(const Duration(hours: 4)),
          createdAt: testDate,
          stats: const {'health': 80, 'happiness': 90},
          metadata: const {'color': 'brown'},
        );
      });

      test('should create pet with all properties', () {
        expect(testPet.id, 'pet-123');
        expect(testPet.name, 'Fluffy');
        expect(testPet.familyId, 'family-123');
        expect(testPet.ownerId, 'child-1');
        expect(testPet.stage, PetStage.child);
        expect(testPet.mood, PetMood.happy);
        expect(testPet.experience, 400);
        expect(testPet.level, 5);
        expect(testPet.currentImageUrl, 'https://example.com/fluffy.jpg');
        expect(testPet.unlockedImageUrls, ['img1.jpg', 'img2.jpg']);
        expect(testPet.stats, {'health': 80, 'happiness': 90});
        expect(testPet.metadata, {'color': 'brown'});
      });

      test('should create pet with minimal properties', () {
        final minimalPet = Pet(
          id: 'minimal-pet',
          name: 'Mini',
          familyId: 'family-456',
          ownerId: 'child-2',
          stage: PetStage.egg,
          mood: PetMood.neutral,
          experience: 0,
          level: 1,
          currentImageUrl: 'egg.jpg',
          lastFedAt: testDate,
          lastPlayedAt: testDate,
          createdAt: testDate,
          stats: const {'health': 100},
        );

        expect(minimalPet.unlockedImageUrls, isEmpty);
        expect(minimalPet.metadata, isNull);
      });

      group('Evolution logic', () {
        test('canEvolve should return false for adult pets', () {
          final adultPet = testPet.copyWith(
            stage: PetStage.adult,
            experience: 2000,
          );
          expect(adultPet.canEvolve, isFalse);
        });

        test('canEvolve should return false when experience is insufficient',
            () {
          final lowExpPet = testPet.copyWith(
            stage: PetStage.child,
            experience: 200, // Need 600 for teen
          );
          expect(lowExpPet.canEvolve, isFalse);
        });

        test('canEvolve should return true when experience meets threshold',
            () {
          final readyToEvolve = testPet.copyWith(
            stage: PetStage.child,
            experience: 600, // Exactly at teen threshold
          );
          expect(readyToEvolve.canEvolve, isTrue);
        });

        test('canEvolve should return true when experience exceeds threshold',
            () {
          final overExperience = testPet.copyWith(
            stage: PetStage.baby,
            experience: 500, // More than 300 needed for child
          );
          expect(overExperience.canEvolve, isTrue);
        });
      });

      group('Care needs', () {
        test('needsFeeding should return false when recently fed', () {
          final recentlyFed = testPet.copyWith(
            lastFedAt: DateTime.now().subtract(const Duration(hours: 2)),
          );
          expect(recentlyFed.needsFeeding, isFalse);
        });

        test('needsFeeding should return true when not fed for 4+ hours', () {
          final hungryPet = testPet.copyWith(
            lastFedAt: DateTime.now().subtract(const Duration(hours: 5)),
          );
          expect(hungryPet.needsFeeding, isTrue);
        });

        test('needsPlay should return false when recently played', () {
          final recentlyPlayed = testPet.copyWith(
            lastPlayedAt: DateTime.now().subtract(const Duration(hours: 3)),
          );
          expect(recentlyPlayed.needsPlay, isFalse);
        });

        test('needsPlay should return true when not played for 6+ hours', () {
          final boredPet = testPet.copyWith(
            lastPlayedAt: DateTime.now().subtract(const Duration(hours: 8)),
          );
          expect(boredPet.needsPlay, isTrue);
        });
      });

      group('copyWith method', () {
        test('should create copy with updated properties', () {
          final updatedPet = testPet.copyWith(
            name: 'Updated Fluffy',
            mood: PetMood.content,
            experience: 500,
            stats: {'health': 85, 'happiness': 95},
          );

          expect(updatedPet.id, testPet.id);
          expect(updatedPet.name, 'Updated Fluffy');
          expect(updatedPet.mood, PetMood.content);
          expect(updatedPet.experience, 500);
          expect(updatedPet.stats, {'health': 85, 'happiness': 95});
          expect(updatedPet.familyId, testPet.familyId);
        });

        test(
            'should preserve existing values when copyWith called without changes',
            () {
          final updatedPet = testPet.copyWith();
          expect(updatedPet.metadata, testPet.metadata);
          expect(updatedPet.name, testPet.name);
          expect(updatedPet.experience, testPet.experience);
        });
      });

      group('Equality and hashCode', () {
        test('should be equal when all properties are same', () {
          final samePet = Pet(
            id: 'pet-123',
            name: 'Fluffy',
            familyId: 'family-123',
            ownerId: 'child-1',
            stage: PetStage.child,
            mood: PetMood.happy,
            experience: 400,
            level: 5,
            currentImageUrl: 'https://example.com/fluffy.jpg',
            unlockedImageUrls: const ['img1.jpg', 'img2.jpg'],
            lastFedAt: testDate.subtract(const Duration(hours: 2)),
            lastPlayedAt: testDate.subtract(const Duration(hours: 4)),
            createdAt: testDate,
            stats: const {'health': 80, 'happiness': 90},
            metadata: const {'color': 'brown'},
          );

          expect(testPet, equals(samePet));
          expect(testPet.hashCode, equals(samePet.hashCode));
        });

        test('should not be equal when properties differ', () {
          final differentPet = testPet.copyWith(name: 'Different Name');

          expect(testPet, isNot(equals(differentPet)));
          expect(testPet.hashCode, isNot(equals(differentPet.hashCode)));
        });

        test('should include all properties in props', () {
          expect(testPet.props, [
            'pet-123',
            'Fluffy',
            'family-123',
            'child-1',
            PetStage.child,
            PetMood.happy,
            400,
            5,
            'https://example.com/fluffy.jpg',
            ['img1.jpg', 'img2.jpg'],
            testDate.subtract(const Duration(hours: 2)),
            testDate.subtract(const Duration(hours: 4)),
            testDate,
            {'health': 80, 'happiness': 90},
            {'color': 'brown'},
          ]);
        });
      });
    });
  });
}
