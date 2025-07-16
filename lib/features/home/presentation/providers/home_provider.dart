import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider =
    StateProvider<int>((ref) => 1); // Default to Pet tab (index 1)

enum HomeTab {
  tasks,
  pet,
  family;

  String get label {
    switch (this) {
      case HomeTab.tasks:
        return 'Tasks';
      case HomeTab.pet:
        return 'Pet';
      case HomeTab.family:
        return 'Family';
    }
  }

  String get icon {
    switch (this) {
      case HomeTab.tasks:
        return 'assets/icons/tasks.svg';
      case HomeTab.pet:
        return 'assets/icons/pet.svg';
      case HomeTab.family:
        return 'assets/icons/family.svg';
    }
  }
}
