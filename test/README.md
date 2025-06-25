# FamilyPet Testing Documentation

This directory contains comprehensive unit tests for the FamilyPet application following clean architecture principles and Flutter testing best practices.

## 📁 Test Structure

The test structure mirrors the main application structure:

```
test/
├── core/
│   └── error/                  # Core error handling tests
│       └── failures_test.dart
├── domain/
│   └── entities/              # Domain entity tests
│       ├── user_test.dart
│       ├── family_test.dart
│       ├── pet_test.dart
│       └── task_test.dart
├── presentation/
│   ├── auth/                  # Authentication presentation tests
│   │   ├── auth_state_test.dart
│   │   └── auth_notifier_test.dart
│   └── home/                  # Home feature tests
│       └── home_provider_test.dart
├── utils/
│   └── test_fixtures.dart     # Reusable test data
├── test_runner.dart           # Main test runner
└── README.md                  # This file
```

## 🧪 Testing Philosophy

### Clean Architecture Testing
- **Domain Layer**: Pure unit tests with no external dependencies
- **Data Layer**: Tests with mocked external services (Supabase, etc.)
- **Presentation Layer**: Tests with mocked repositories and domain services

### Test Categories

1. **Entity Tests**: Test domain entities for:
   - Property validation
   - Business logic methods
   - Equality and hashCode
   - copyWith functionality
   - Computed properties

2. **State Management Tests**: Test providers/notifiers for:
   - State transitions
   - Error handling
   - Side effects
   - Dependency injection

3. **Repository Tests**: Test data layer for:
   - API interaction
   - Error handling
   - Data transformation
   - Caching logic

4. **Use Case Tests**: Test business logic for:
   - Input validation
   - Business rules
   - Error scenarios
   - Success paths

## 🔧 Testing Tools

### Core Dependencies
- `test: ^1.24.9` - Dart testing framework
- `mockito: ^5.4.4` - Mocking framework
- `flutter_test` - Flutter testing utilities

### Test Utilities
- `TestFixtures` - Centralized test data
- Mock generation via `@GenerateMocks`
- Custom matchers for domain-specific assertions

## 🏃‍♂️ Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/domain/entities/user_test.dart
```

### Run Test Group
```bash
flutter test --plain-name "User Entity Tests"
```

### Run with Coverage
```bash
flutter test --coverage
```

### Run Test Runner
```bash
flutter test test/test_runner.dart
```

## 📋 Test Conventions

### Naming Conventions
- Test files end with `_test.dart`
- Test classes follow `ClassNameTest` pattern
- Test methods use descriptive names: `should_returnSuccess_when_validInputProvided`

### Test Structure
Each test file follows this structure:
```dart
import 'package:test/test.dart';
// Other imports...

void main() {
  group('ClassName Tests', () {
    late ClassName objectUnderTest;
    
    setUp(() {
      // Setup code
    });
    
    tearDown(() {
      // Cleanup code
    });
    
    group('Feature Group', () {
      test('should behave correctly when condition met', () {
        // Arrange
        
        // Act
        
        // Assert
      });
    });
  });
}
```

### Test Organization
- Use `group()` to organize related tests
- Use `setUp()` and `tearDown()` for common initialization
- Follow Arrange-Act-Assert pattern
- One assertion per test when possible

## 🎯 Test Coverage Goals

### Domain Layer (100% Coverage)
- All entities and their methods
- All enums and their properties
- All computed properties
- All business logic methods

### Presentation Layer (90%+ Coverage)
- State management classes
- Provider logic
- State transitions
- Error handling

### Data Layer (85%+ Coverage)
- Repository implementations
- Data source interactions
- Error handling
- Data transformations

## 🔍 Test Categories by Feature

### Authentication Feature
- `auth_state_test.dart` - Auth state management
- `auth_notifier_test.dart` - Auth business logic
- Repository tests for Supabase integration

### Home Feature
- `home_provider_test.dart` - Tab navigation and state

### Family Feature
- Entity tests for family management
- Repository tests for family operations

### Pet Feature
- Entity tests for pet evolution and care
- Business logic for pet interactions

### Task Feature
- Entity tests for task lifecycle
- Business logic for task verification

## 🚀 Best Practices

### 1. Use Test Fixtures
```dart
import '../utils/test_fixtures.dart';

test('should create user correctly', () {
  final user = TestFixtures.testParent;
  expect(user.role, UserRole.parent);
});
```

### 2. Mock Dependencies
```dart
@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
  });
}
```

### 3. Test Error Scenarios
```dart
test('should handle network failure', () async {
  when(mockRepository.signIn(any, any))
      .thenThrow(NetworkException('No internet'));
  
  final result = await useCase.signIn('email', 'password');
  
  expect(result.isLeft(), isTrue);
});
```

### 4. Verify Interactions
```dart
test('should call repository with correct parameters', () async {
  await notifier.signIn('test@example.com', 'password');
  
  verify(mockRepository.signIn('test@example.com', 'password'))
      .called(1);
});
```

### 5. Test State Transitions
```dart
test('should transition from loading to authenticated', () async {
  expect(notifier.state.status, AuthStatus.loading);
  
  await completeSignIn();
  
  expect(notifier.state.status, AuthStatus.authenticated);
});
```

## 📊 Continuous Integration

Tests are run automatically on:
- Pull requests
- Main branch commits
- Release preparations

### CI Requirements
- All tests must pass
- Coverage threshold must be met
- No test warnings or errors
- Test execution time within limits

## 🔧 Debugging Tests

### Common Issues
1. **Async Tests**: Use `await` and `Future.delayed` appropriately
2. **State Persistence**: Ensure proper cleanup in `tearDown`
3. **Mock Setup**: Verify mocks are configured before use
4. **Test Isolation**: Each test should be independent

### Debugging Tips
```dart
// Add debug prints
test('debug test', () {
  print('State: ${notifier.state}');
  // test logic
});

// Use expectAsync for async callbacks
test('async callback test', () {
  notifier.addListener(expectAsync1((state) {
    expect(state.isLoading, isFalse);
  }));
});
```

## 📈 Future Enhancements

- [ ] Integration tests for critical user flows
- [ ] Widget tests for complex UI components
- [ ] Golden tests for UI consistency
- [ ] Performance tests for data operations
- [ ] Accessibility tests
- [ ] Platform-specific tests (iOS/Android)

## 📚 Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Test Package Documentation](https://pub.dev/packages/test)
- [Clean Architecture Testing Patterns](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

For questions about testing or to contribute new tests, please refer to the project's contributing guidelines. 