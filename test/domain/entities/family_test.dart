import 'package:test/test.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';

void main() {
  group('Family Entity Tests', () {
    late Family testFamily;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testFamily = Family(
        id: 'family-123',
        name: 'Test Family',
        inviteCode: 'ABC123',
        createdById: 'parent-1',
        parentIds: const ['parent-1', 'parent-2'],
        childIds: const ['child-1', 'child-2', 'child-3'],
        createdAt: testDate,
        lastActivityAt: testDate,
        settings: const {'theme': 'light'},
        metadata: const {'version': '1.0'},
      );
    });

    group('Family creation', () {
      test('should create family with all properties', () {
        expect(testFamily.id, 'family-123');
        expect(testFamily.name, 'Test Family');
        expect(testFamily.inviteCode, 'ABC123');
        expect(testFamily.createdById, 'parent-1');
        expect(testFamily.parentIds, ['parent-1', 'parent-2']);
        expect(testFamily.childIds, ['child-1', 'child-2', 'child-3']);
        expect(testFamily.createdAt, testDate);
        expect(testFamily.lastActivityAt, testDate);
        expect(testFamily.settings, {'theme': 'light'});
        expect(testFamily.metadata, {'version': '1.0'});
      });

      test('should create family with minimal required properties', () {
        final minimalFamily = Family(
          id: 'family-minimal',
          name: 'Minimal Family',
          inviteCode: 'MIN123',
          createdById: 'parent-only',
          createdAt: testDate,
        );

        expect(minimalFamily.id, 'family-minimal');
        expect(minimalFamily.name, 'Minimal Family');
        expect(minimalFamily.parentIds, isEmpty);
        expect(minimalFamily.childIds, isEmpty);
        expect(minimalFamily.lastActivityAt, isNull);
        expect(minimalFamily.settings, isNull);
        expect(minimalFamily.metadata, isNull);
      });
    });

    group('Computed properties', () {
      test('totalMembers should return sum of parents and children', () {
        expect(testFamily.totalMembers, 5); // 2 parents + 3 children
      });

      test('hasChildren should return true when children exist', () {
        expect(testFamily.hasChildren, isTrue);
      });

      test('hasChildren should return false when no children', () {
        final noChildrenFamily = testFamily.copyWith(childIds: []);
        expect(noChildrenFamily.hasChildren, isFalse);
      });

      test('hasMultipleParents should return true when multiple parents', () {
        expect(testFamily.hasMultipleParents, isTrue);
      });

      test('hasMultipleParents should return false when single parent', () {
        final singleParentFamily = testFamily.copyWith(parentIds: ['parent-1']);
        expect(singleParentFamily.hasMultipleParents, isFalse);
      });

      test('isActive should return true when activity is recent', () {
        final recentActivity = testFamily.copyWith(
          lastActivityAt: DateTime.now().subtract(const Duration(days: 15)),
        );
        expect(recentActivity.isActive, isTrue);
      });

      test('isActive should return false when activity is old', () {
        final oldActivity = testFamily.copyWith(
          lastActivityAt: DateTime.now().subtract(const Duration(days: 35)),
        );
        expect(oldActivity.isActive, isFalse);
      });

      test('isActive should return false when lastActivityAt is null', () {
        final noActivity = testFamily.copyWith(lastActivityAt: null);
        expect(noActivity.isActive, isFalse);
      });
    });

    group('Member checking methods', () {
      test('isMember should return true for parents', () {
        expect(testFamily.isMember('parent-1'), isTrue);
        expect(testFamily.isMember('parent-2'), isTrue);
      });

      test('isMember should return true for children', () {
        expect(testFamily.isMember('child-1'), isTrue);
        expect(testFamily.isMember('child-2'), isTrue);
        expect(testFamily.isMember('child-3'), isTrue);
      });

      test('isMember should return false for non-members', () {
        expect(testFamily.isMember('stranger-123'), isFalse);
      });

      test('isParent should return true for parent members', () {
        expect(testFamily.isParent('parent-1'), isTrue);
        expect(testFamily.isParent('parent-2'), isTrue);
      });

      test('isParent should return false for children and strangers', () {
        expect(testFamily.isParent('child-1'), isFalse);
        expect(testFamily.isParent('stranger-123'), isFalse);
      });

      test('isChild should return true for child members', () {
        expect(testFamily.isChild('child-1'), isTrue);
        expect(testFamily.isChild('child-2'), isTrue);
        expect(testFamily.isChild('child-3'), isTrue);
      });

      test('isChild should return false for parents and strangers', () {
        expect(testFamily.isChild('parent-1'), isFalse);
        expect(testFamily.isChild('stranger-123'), isFalse);
      });
    });

    group('copyWith method', () {
      test('should create copy with updated properties', () {
        final updatedFamily = testFamily.copyWith(
          name: 'Updated Family Name',
          inviteCode: 'NEW123',
          parentIds: ['parent-1'],
        );

        expect(updatedFamily.id, testFamily.id);
        expect(updatedFamily.name, 'Updated Family Name');
        expect(updatedFamily.inviteCode, 'NEW123');
        expect(updatedFamily.parentIds, ['parent-1']);
        expect(updatedFamily.childIds, testFamily.childIds);
        expect(updatedFamily.createdAt, testFamily.createdAt);
      });

      test(
          'should preserve existing values when copyWith called without changes',
          () {
        final updatedFamily = testFamily.copyWith();

        expect(updatedFamily.lastActivityAt, testFamily.lastActivityAt);
        expect(updatedFamily.settings, testFamily.settings);
        expect(updatedFamily.metadata, testFamily.metadata);
        expect(updatedFamily.name, testFamily.name);
      });
    });

    group('Equality and hashCode', () {
      test('should be equal when all properties are same', () {
        final sameFamily = Family(
          id: 'family-123',
          name: 'Test Family',
          inviteCode: 'ABC123',
          createdById: 'parent-1',
          parentIds: const ['parent-1', 'parent-2'],
          childIds: const ['child-1', 'child-2', 'child-3'],
          createdAt: testDate,
          lastActivityAt: testDate,
          settings: const {'theme': 'light'},
          metadata: const {'version': '1.0'},
        );

        expect(testFamily, equals(sameFamily));
        expect(testFamily.hashCode, equals(sameFamily.hashCode));
      });

      test('should not be equal when properties differ', () {
        final differentFamily = testFamily.copyWith(name: 'Different Family');

        expect(testFamily, isNot(equals(differentFamily)));
        expect(testFamily.hashCode, isNot(equals(differentFamily.hashCode)));
      });

      test('should include all properties in props', () {
        expect(testFamily.props, [
          'family-123',
          'Test Family',
          'ABC123',
          'parent-1',
          ['parent-1', 'parent-2'],
          ['child-1', 'child-2', 'child-3'],
          testDate,
          testDate,
          {'theme': 'light'},
          {'version': '1.0'},
        ]);
      });
    });
  });
}
