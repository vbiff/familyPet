import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service that manages pet mood decay and interaction timing
///
/// Features:
/// - Happiness decreases randomly 10-20% each hour
/// - Health decreases randomly 30-50% once per week
/// - Play with pet limited to once per hour (5% happiness increase)
/// - Task completion restores happiness to 100%
/// - Medical care restores health to 100%
/// - Pet grows every 2 days (handled elsewhere)
class PetMoodService {
  static final PetMoodService _instance = PetMoodService._internal();
  factory PetMoodService() => _instance;
  PetMoodService._internal();

  final Logger _logger = Logger();
  Timer? _hourlyDecayTimer;
  Timer? _weeklyHealthDecayTimer;
  final Random _random = Random();

  // Track last interaction times per pet
  final Map<String, DateTime> _lastPlayTimes = {};
  final Map<String, DateTime> _lastFeedTimes = {};
  final Map<String, DateTime> _lastHealTimes = {};
  final Map<String, DateTime> _lastHealthDecayTimes = {};

  bool _isInitialized = false;

  /// Initialize the mood service with hourly happiness decay and weekly health decay
  void initialize() {
    if (_isInitialized) return;

    _logger.i(
        '🐾 Initializing Pet Mood Service with hourly happiness decay and weekly health decay');

    // Start hourly timer for happiness decay
    _startHourlyDecayTimer();

    // Start weekly timer for health decay
    _startWeeklyHealthDecayTimer();

    _isInitialized = true;
    _logger.i('✅ Pet Mood Service initialized successfully');
  }

  /// Start the hourly timer for happiness decay
  void _startHourlyDecayTimer() {
    _hourlyDecayTimer?.cancel();

    // Run every hour
    _hourlyDecayTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _logger.d('⏰ Hourly pet happiness decay triggered');
      _applyHourlyHappinessDecay();
    });

    _logger.d('⏱️ Hourly decay timer started');
  }

  /// Start the weekly timer for health decay
  void _startWeeklyHealthDecayTimer() {
    _weeklyHealthDecayTimer?.cancel();

    // Run every week (7 days)
    _weeklyHealthDecayTimer = Timer.periodic(const Duration(days: 7), (timer) {
      _logger.d('📅 Weekly pet health decay triggered');
      _applyWeeklyHealthDecay();
    });

    _logger.d('⏱️ Weekly health decay timer started');
  }

  /// Apply random 10-20% happiness decay to all pets
  Future<void> _applyHourlyHappinessDecay() async {
    try {
      _logger.i('🔄 Applying hourly happiness decay to all pets');

      // This will be called by the pet provider to apply decay to all family pets
      // For now, we'll emit an event that providers can listen to
      _notifyHappinessDecayNeeded();
    } catch (e) {
      _logger.e('❌ Error applying hourly happiness decay: $e');
    }
  }

  /// Apply random 30-50% health decay to all pets (weekly)
  Future<void> _applyWeeklyHealthDecay() async {
    try {
      _logger.i('🏥 Applying weekly health decay to all pets');

      // This will be called by the pet provider to apply health decay to all family pets
      _notifyHealthDecayNeeded();
    } catch (e) {
      _logger.e('❌ Error applying weekly health decay: $e');
    }
  }

  /// Calculate random happiness decay between 10-20%
  int calculateHappinessDecay(int currentHappiness) {
    // Random decay between 10% and 20%
    final decayPercentage = 10 + _random.nextInt(11); // 10-20%
    final decayAmount = (currentHappiness * decayPercentage / 100).round();

    _logger.d('💔 Happiness decay: $decayPercentage% ($decayAmount points)');
    return decayAmount;
  }

  /// Calculate random health decay between 30-50%
  int calculateHealthDecay(int currentHealth) {
    // Random decay between 30% and 50%
    final decayPercentage = 30 + _random.nextInt(21); // 30-50%
    final decayAmount = (currentHealth * decayPercentage / 100).round();

    _logger.d('🏥 Health decay: $decayPercentage% ($decayAmount points)');
    return decayAmount;
  }

  /// Check if pet can play (once per hour limit)
  bool canPlayWithPet(String petId) {
    final lastPlayTime = _lastPlayTimes[petId];
    if (lastPlayTime == null) return true;

    final hoursSinceLastPlay = DateTime.now().difference(lastPlayTime).inHours;
    final canPlay = hoursSinceLastPlay >= 1;

    _logger.d(
        '🎮 Can play with pet $petId: $canPlay (${hoursSinceLastPlay}h since last play)');
    return canPlay;
  }

  /// Check if pet can be fed (no time limit, but track for analytics)
  bool canFeedPet(String petId) {
    // No time limit for feeding, but we track it
    return true;
  }

  /// Check if pet can be healed (no time limit, but track for analytics)
  bool canHealPet(String petId) {
    // No time limit for healing, but we track it
    return true;
  }

  /// Check if health decay should be applied to this pet (once per week)
  bool shouldApplyHealthDecay(String petId) {
    final lastHealthDecayTime = _lastHealthDecayTimes[petId];
    if (lastHealthDecayTime == null) return true;

    final daysSinceLastDecay =
        DateTime.now().difference(lastHealthDecayTime).inDays;
    final shouldDecay = daysSinceLastDecay >= 7;

    _logger.d(
        '🏥 Should apply health decay to pet $petId: $shouldDecay ($daysSinceLastDecay days since last decay)');
    return shouldDecay;
  }

  /// Record that pet was played with
  void recordPlayInteraction(String petId) {
    _lastPlayTimes[petId] = DateTime.now();
    _logger.d('🎮 Recorded play interaction for pet $petId');
  }

  /// Record that pet was fed
  void recordFeedInteraction(String petId) {
    _lastFeedTimes[petId] = DateTime.now();
    _logger.d('🍖 Recorded feed interaction for pet $petId');
  }

  /// Record that pet was healed
  void recordHealInteraction(String petId) {
    _lastHealTimes[petId] = DateTime.now();
    _logger.d('💊 Recorded heal interaction for pet $petId');
  }

  /// Record that health decay was applied to this pet
  void recordHealthDecay(String petId) {
    _lastHealthDecayTimes[petId] = DateTime.now();
    _logger.d('🏥 Recorded health decay for pet $petId');
  }

  /// Get time until next play is allowed
  Duration? getTimeUntilNextPlay(String petId) {
    final lastPlayTime = _lastPlayTimes[petId];
    if (lastPlayTime == null) return null;

    final nextPlayTime = lastPlayTime.add(const Duration(hours: 1));
    final now = DateTime.now();

    if (now.isAfter(nextPlayTime)) return null;

    return nextPlayTime.difference(now);
  }

  /// Calculate happiness increase for playing (5%)
  int calculatePlayHappinessIncrease(int currentHappiness) {
    const increasePercentage = 5;
    final increaseAmount =
        (100 * increasePercentage / 100).round(); // 5% of max happiness (100)

    _logger.d(
        '😊 Play happiness increase: $increasePercentage% ($increaseAmount points)');
    return increaseAmount;
  }

  /// Reset happiness to 100% when task is completed
  int calculateTaskCompletionHappiness() {
    _logger.d('🎉 Task completed! Happiness restored to 100%');
    return 100;
  }

  /// Reset health to 100% when medical care is given
  int calculateMedicalCareHealth() {
    _logger.d('💊 Medical care given! Health restored to 100%');
    return 100;
  }

  /// Get analytics about pet interactions
  Map<String, dynamic> getInteractionAnalytics(String petId) {
    return {
      'lastPlayTime': _lastPlayTimes[petId]?.toIso8601String(),
      'lastFeedTime': _lastFeedTimes[petId]?.toIso8601String(),
      'lastHealTime': _lastHealTimes[petId]?.toIso8601String(),
      'lastHealthDecayTime': _lastHealthDecayTimes[petId]?.toIso8601String(),
      'canPlay': canPlayWithPet(petId),
      'timeUntilNextPlay': getTimeUntilNextPlay(petId)?.inMinutes,
      'shouldApplyHealthDecay': shouldApplyHealthDecay(petId),
    };
  }

  /// Callback for when happiness decay is needed
  static void Function()? _onHappinessDecayNeeded;

  /// Callback for when health decay is needed
  static void Function()? _onHealthDecayNeeded;

  /// Set callback for happiness decay notifications
  static void setHappinessDecayCallback(void Function() callback) {
    _onHappinessDecayNeeded = callback;
  }

  /// Set callback for health decay notifications
  static void setHealthDecayCallback(void Function() callback) {
    _onHealthDecayNeeded = callback;
  }

  /// Notify that happiness decay is needed (for providers to listen)
  void _notifyHappinessDecayNeeded() {
    _logger.d('📢 Happiness decay notification sent');

    // Trigger the callback if set
    if (_onHappinessDecayNeeded != null) {
      try {
        _onHappinessDecayNeeded!();
        _logger.d('✅ Happiness decay callback executed successfully');
      } catch (e) {
        _logger.e('❌ Error executing happiness decay callback: $e');
      }
    } else {
      _logger.w('⚠️ No happiness decay callback set');
    }
  }

  /// Notify that health decay is needed (for providers to listen)
  void _notifyHealthDecayNeeded() {
    _logger.d('📢 Health decay notification sent');

    // Trigger the callback if set
    if (_onHealthDecayNeeded != null) {
      try {
        _onHealthDecayNeeded!();
        _logger.d('✅ Health decay callback executed successfully');
      } catch (e) {
        _logger.e('❌ Error executing health decay callback: $e');
      }
    } else {
      _logger.w('⚠️ No health decay callback set');
    }
  }

  /// Apply happiness decay to a specific pet
  Map<String, int> applyHappinessDecay(Map<String, int> currentStats) {
    final currentHappiness = currentStats['happiness'] ?? 100;
    final decayAmount = calculateHappinessDecay(currentHappiness);
    final newHappiness = (currentHappiness - decayAmount).clamp(0, 100);

    final newStats = Map<String, int>.from(currentStats);
    newStats['happiness'] = newHappiness;

    _logger.i('💔 Applied happiness decay: $currentHappiness → $newHappiness');
    return newStats;
  }

  /// Apply health decay to a specific pet (30-50% randomly, once per week)
  Map<String, int> applyHealthDecay(
      Map<String, int> currentStats, String petId) {
    final currentHealth = currentStats['health'] ?? 100;

    // Only apply if enough time has passed
    if (!shouldApplyHealthDecay(petId)) {
      _logger.d('🏥 Health decay skipped for pet $petId (not yet time)');
      return currentStats;
    }

    final decayAmount = calculateHealthDecay(currentHealth);
    final newHealth = (currentHealth - decayAmount).clamp(0, 100);

    final newStats = Map<String, int>.from(currentStats);
    newStats['health'] = newHealth;

    // Record that decay was applied
    recordHealthDecay(petId);

    _logger.i('🏥 Applied health decay: $currentHealth → $newHealth');
    return newStats;
  }

  /// Apply task completion happiness boost (100%)
  Map<String, int> applyTaskCompletionBoost(Map<String, int> currentStats) {
    final newStats = Map<String, int>.from(currentStats);
    newStats['happiness'] = 100; // Always restore to 100%

    _logger.i('🎉 Applied task completion happiness boost: happiness → 100%');
    return newStats;
  }

  /// Apply play happiness increase (5%)
  Map<String, int> applyPlayHappinessIncrease(Map<String, int> currentStats) {
    final currentHappiness = currentStats['happiness'] ?? 100;
    final increaseAmount = calculatePlayHappinessIncrease(currentHappiness);
    final newHappiness = (currentHappiness + increaseAmount).clamp(0, 100);

    final newStats = Map<String, int>.from(currentStats);
    newStats['happiness'] = newHappiness;

    _logger.i(
        '😊 Applied play happiness increase: $currentHappiness → $newHappiness');
    return newStats;
  }

  /// Apply medical care (restore health to 100%, don't affect happiness)
  Map<String, int> applyMedicalCare(Map<String, int> currentStats) {
    final newStats = Map<String, int>.from(currentStats);
    newStats['health'] = 100; // Always restore health to 100%
    // Do NOT modify happiness - only health

    _logger.i('💊 Applied medical care: health → 100% (happiness unchanged)');
    return newStats;
  }

  /// Dispose of resources
  void dispose() {
    _hourlyDecayTimer?.cancel();
    _hourlyDecayTimer = null;
    _weeklyHealthDecayTimer?.cancel();
    _weeklyHealthDecayTimer = null;
    _isInitialized = false;
    _logger.i('🧹 Pet Mood Service disposed');
  }

  /// Force trigger happiness decay for testing
  @visibleForTesting
  void forceHappinessDecay() {
    _logger.d('🧪 Force triggering happiness decay for testing');
    _applyHourlyHappinessDecay();
  }

  /// Force trigger health decay for testing
  @visibleForTesting
  void forceHealthDecay() {
    _logger.d('🧪 Force triggering health decay for testing');
    _applyWeeklyHealthDecay();
  }
}
