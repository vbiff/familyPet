import 'package:test/test.dart';
import 'package:jhonny/features/home/presentation/providers/home_provider.dart';

void main() {
  group('Home Provider Tests', () {
    group('HomeTab enum', () {
      test('should have correct label values', () {
        expect(HomeTab.tasks.label, 'Tasks');
        expect(HomeTab.pet.label, 'Pet');
        expect(HomeTab.family.label, 'Family');
      });

      test('should have correct icon values', () {
        expect(HomeTab.tasks.icon, 'assets/icons/tasks.svg');
        expect(HomeTab.pet.icon, 'assets/icons/pet.svg');
        expect(HomeTab.family.icon, 'assets/icons/family.svg');
      });

      test('should have all expected tab values', () {
        expect(HomeTab.values, [
          HomeTab.tasks,
          HomeTab.pet,
          HomeTab.family,
        ]);
      });

      test('should map index to correct tab', () {
        expect(HomeTab.values[0], HomeTab.tasks);
        expect(HomeTab.values[1], HomeTab.pet);
        expect(HomeTab.values[2], HomeTab.family);
      });
    });

    group('HomeTab properties', () {
      test('tasks tab should have correct properties', () {
        const tab = HomeTab.tasks;
        expect(tab.label, 'Tasks');
        expect(tab.icon, 'assets/icons/tasks.svg');
      });

      test('pet tab should have correct properties', () {
        const tab = HomeTab.pet;
        expect(tab.label, 'Pet');
        expect(tab.icon, 'assets/icons/pet.svg');
      });

      test('family tab should have correct properties', () {
        const tab = HomeTab.family;
        expect(tab.label, 'Family');
        expect(tab.icon, 'assets/icons/family.svg');
      });
    });

    group('Tab navigation', () {
      test('should have correct number of tabs', () {
        expect(HomeTab.values.length, 3);
      });

      test('should support iteration over all tabs', () {
        final labels = HomeTab.values.map((tab) => tab.label).toList();
        expect(labels, ['Tasks', 'Pet', 'Family']);

        final icons = HomeTab.values.map((tab) => tab.icon).toList();
        expect(icons, [
          'assets/icons/tasks.svg',
          'assets/icons/pet.svg',
          'assets/icons/family.svg',
        ]);
      });
    });

    group('String representation', () {
      test('should have string representation matching label', () {
        // Note: This tests the enum name, not the label getter
        expect(HomeTab.tasks.toString(), 'HomeTab.tasks');
        expect(HomeTab.pet.toString(), 'HomeTab.pet');
        expect(HomeTab.family.toString(), 'HomeTab.family');
      });
    });

    group('Enum comparisons', () {
      test('should support equality comparisons', () {
        expect(HomeTab.tasks == HomeTab.tasks, isTrue);
        expect(HomeTab.tasks == HomeTab.pet, isFalse);
        expect(HomeTab.pet == HomeTab.family, isFalse);
      });

      test('should support identity comparisons', () {
        expect(identical(HomeTab.tasks, HomeTab.tasks), isTrue);
        expect(identical(HomeTab.tasks, HomeTab.pet), isFalse);
      });
    });

    group('Tab indexing', () {
      test('should match expected indexes for navigation', () {
        // These indexes are commonly used for NavigationBar selectedIndex
        expect(HomeTab.values.indexOf(HomeTab.tasks), 0);
        expect(HomeTab.values.indexOf(HomeTab.pet), 1);
        expect(HomeTab.values.indexOf(HomeTab.family), 2);
      });

      test('should allow reverse lookup by index', () {
        expect(HomeTab.values[0], HomeTab.tasks);
        expect(HomeTab.values[1], HomeTab.pet);
        expect(HomeTab.values[2], HomeTab.family);
      });
    });

    group('Icon paths validation', () {
      test('should have valid SVG file extensions', () {
        for (final tab in HomeTab.values) {
          expect(tab.icon.endsWith('.svg'), isTrue,
              reason: 'Tab ${tab.label} should have SVG icon');
        }
      });

      test('should have assets path prefix', () {
        for (final tab in HomeTab.values) {
          expect(tab.icon.startsWith('assets/icons/'), isTrue,
              reason: 'Tab ${tab.label} should have correct assets path');
        }
      });
    });

    group('Label validation', () {
      test('should have non-empty labels', () {
        for (final tab in HomeTab.values) {
          expect(tab.label.isNotEmpty, isTrue,
              reason: 'Tab ${tab.name} should have non-empty label');
        }
      });

      test('should have title case labels', () {
        for (final tab in HomeTab.values) {
          final label = tab.label;
          expect(label[0], equals(label[0].toUpperCase()),
              reason: 'Tab label "$label" should start with uppercase');
        }
      });
    });
  });
}
