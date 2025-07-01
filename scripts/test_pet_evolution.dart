import 'dart:io';

/// Test script to verify pet auto-evolution
///
/// Usage: dart run scripts/test_pet_evolution.dart
///
/// This script shows SQL commands to test the evolution system:
/// 1. Update pet creation date to simulate different ages
/// 2. Test each evolution stage
/// 3. Verify the auto-evolution logic

void main() {
  print('🧪 Pet Auto-Evolution Test Script');
  print('===================================\n');

  print('Copy and paste these SQL commands in your Supabase SQL Editor:\n');

  // Show current pets
  print('1️⃣ Check current pets:');
  print('```sql');
  print('SELECT id, name, stage, created_at, ');
  print('  EXTRACT(DAY FROM (NOW() - created_at)) as age_in_days');
  print('FROM pets;');
  print('```\n');

  // Test evolution stages
  final tests = [
    {
      'stage': 'egg',
      'days': 0,
      'shouldBe': 'egg',
      'description': 'New pet (should stay egg)'
    },
    {
      'stage': 'baby',
      'days': 2,
      'shouldBe': 'baby',
      'description': '2 days old (should evolve to baby)'
    },
    {
      'stage': 'child',
      'days': 4,
      'shouldBe': 'child',
      'description': '4 days old (should evolve to child)'
    },
    {
      'stage': 'teen',
      'days': 6,
      'shouldBe': 'teen',
      'description': '6 days old (should evolve to teen)'
    },
    {
      'stage': 'adult',
      'days': 8,
      'shouldBe': 'adult',
      'description': '8+ days old (should evolve to adult)'
    },
  ];

  for (int i = 0; i < tests.length; i++) {
    final test = tests[i];
    print('${i + 2}️⃣ Test ${test['description']}:');
    print('```sql');
    print('-- Set pet to ${test['days']} days old');
    print(
        'UPDATE pets SET created_at = NOW() - INTERVAL \'${test['days']} days\'');
    print('WHERE id = (SELECT id FROM pets LIMIT 1);');
    print('');
    print('-- Verify age');
    print('SELECT name, stage, ');
    print('  EXTRACT(DAY FROM (NOW() - created_at)) as age_in_days,');
    print('  \'Should be ${test['shouldBe']}\' as expected_stage');
    print('FROM pets;');
    print('```\n');
  }

  print('🔄 After running each test:');
  print('1. Execute the UPDATE command');
  print('2. Open your Flutter app');
  print('3. Navigate to the Pet tab');
  print('4. Check if the pet evolved to the expected stage');
  print('5. Check if evolution message appears\n');

  print('📊 Evolution Timeline:');
  print('• Day 0-1: 🥚 Egg');
  print('• Day 2-3: 🐣 Baby');
  print('• Day 4-5: 🐕 Child');
  print('• Day 6-7: 🦮 Teen');
  print('• Day 8+:  🐺 Adult\n');

  print('✅ Reset pet to current time:');
  print('```sql');
  print('UPDATE pets SET created_at = NOW();');
  print('```\n');

  print(
      '🎉 Happy testing! Your pet should now grow automatically every 2 days!');
}
