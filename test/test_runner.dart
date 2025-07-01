import 'package:test/test.dart';

// Domain Entity Tests
import 'domain/entities/user_test.dart' as user_tests;
import 'domain/entities/family_test.dart' as family_tests;
import 'domain/entities/pet_test.dart' as pet_tests;
import 'domain/entities/task_test.dart' as task_tests;

// Core Error Tests
import 'core/error/failures_test.dart' as failure_tests;

// Presentation Layer Tests
import 'presentation/auth/auth_state_test.dart' as auth_state_tests;
import 'presentation/home/home_provider_test.dart' as home_provider_tests;

// Use Case Tests
import 'features/task/domain/usecases/update_task_status_test.dart'
    as update_task_status_tests;

// Data Model Tests
import 'features/task/data/models/task_model_test.dart' as task_model_tests;

// Provider Tests
import 'features/task/presentation/providers/task_notifier_test.dart'
    as task_notifier_tests;
import 'features/auth/presentation/providers/auth_notifier_test.dart'
    as auth_notifier_tests;

// Widget Tests
import 'features/task/presentation/widgets/task_list_test.dart'
    as task_list_widget_tests;

void main() {
  group('FamilyPet App Tests', () {
    group('Domain Layer Tests', () {
      group('Entity Tests', () {
        user_tests.main();
        family_tests.main();
        pet_tests.main();
        task_tests.main();
      });

      group('Use Case Tests', () {
        update_task_status_tests.main();
      });
    });

    group('Data Layer Tests', () {
      group('Model Tests', () {
        task_model_tests.main();
      });
    });

    group('Core Layer Tests', () {
      failure_tests.main();
    });

    group('Presentation Layer Tests', () {
      group('Auth Tests', () {
        auth_state_tests.main();
        auth_notifier_tests.main();
      });

      group('Task Tests', () {
        task_notifier_tests.main();
      });

      group('Home Tests', () {
        home_provider_tests.main();
      });

      group('Widget Tests', () {
        task_list_widget_tests.main();
      });
    });
  });
}
