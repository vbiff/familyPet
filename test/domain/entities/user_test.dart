import 'package:test/test.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity Tests', () {
    group('UserRole enum', () {
      test('should have correct string names', () {
        expect(UserRole.parent.name, 'parent');
        expect(UserRole.child.name, 'child');
      });
    });

    group('User class', () {
      late User testUser;
      late DateTime testDate;

      setUp(() {
        testDate = DateTime(2024, 1, 1, 12, 0, 0);
        testUser = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.parent,
          createdAt: testDate,
          lastLoginAt: testDate,
          avatarUrl: 'https://example.com/avatar.jpg',
          familyId: 'family-123',
          metadata: const {'key': 'value'},
        );
      });

      test('should create user with all properties', () {
        expect(testUser.id, 'test-id');
        expect(testUser.email, 'test@example.com');
        expect(testUser.displayName, 'Test User');
        expect(testUser.role, UserRole.parent);
        expect(testUser.createdAt, testDate);
        expect(testUser.lastLoginAt, testDate);
        expect(testUser.avatarUrl, 'https://example.com/avatar.jpg');
        expect(testUser.familyId, 'family-123');
        expect(testUser.metadata, {'key': 'value'});
      });

      test('should create user with required properties only', () {
        final minimalUser = User(
          id: 'minimal-id',
          email: 'minimal@example.com',
          displayName: 'Minimal User',
          role: UserRole.child,
          createdAt: testDate,
          lastLoginAt: testDate,
        );

        expect(minimalUser.id, 'minimal-id');
        expect(minimalUser.email, 'minimal@example.com');
        expect(minimalUser.displayName, 'Minimal User');
        expect(minimalUser.role, UserRole.child);
        expect(minimalUser.avatarUrl, isNull);
        expect(minimalUser.familyId, isNull);
        expect(minimalUser.metadata, isNull);
      });

      test('should support copyWith method', () {
        final updatedUser = testUser.copyWith(
          displayName: 'Updated Name',
          avatarUrl: 'https://example.com/new-avatar.jpg',
        );

        expect(updatedUser.id, testUser.id);
        expect(updatedUser.email, testUser.email);
        expect(updatedUser.displayName, 'Updated Name');
        expect(updatedUser.role, testUser.role);
        expect(updatedUser.avatarUrl, 'https://example.com/new-avatar.jpg');
        expect(updatedUser.familyId, testUser.familyId);
      });

      test(
          'should preserve existing values when copyWith called without changes',
          () {
        final updatedUser = testUser.copyWith();

        expect(updatedUser.avatarUrl, testUser.avatarUrl);
        expect(updatedUser.familyId, testUser.familyId);
        expect(updatedUser.displayName, testUser.displayName);
        expect(updatedUser.email, testUser.email);
      });

      test('should be equal when properties are same', () {
        final sameUser = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.parent,
          createdAt: testDate,
          lastLoginAt: testDate,
          avatarUrl: 'https://example.com/avatar.jpg',
          familyId: 'family-123',
          metadata: const {'key': 'value'},
        );

        expect(testUser, equals(sameUser));
        expect(testUser.hashCode, equals(sameUser.hashCode));
      });

      test('should not be equal when properties differ', () {
        final differentUser = testUser.copyWith(displayName: 'Different Name');

        expect(testUser, isNot(equals(differentUser)));
        expect(testUser.hashCode, isNot(equals(differentUser.hashCode)));
      });

      test('should include all properties in props', () {
        expect(testUser.props, [
          'test-id',
          'test@example.com',
          'Test User',
          UserRole.parent,
          testDate,
          testDate,
          'https://example.com/avatar.jpg',
          'family-123',
          {'key': 'value'},
        ]);
      });
    });
  });
}
