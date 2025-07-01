import 'dart:math';

import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

enum AnalyticsPeriod { daily, weekly, monthly, yearly }

class FamilyAnalytics {
  final String familyId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalTasks;
  final int completedTasks;
  final int totalPoints;
  final Map<String, MemberAnalytics> memberAnalytics;
  final List<DailyStats> dailyStats;
  final Map<TaskCategory, int> tasksByCategory;
  final Map<TaskDifficulty, int> tasksByDifficulty;

  FamilyAnalytics({
    required this.familyId,
    required this.startDate,
    required this.endDate,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalPoints,
    required this.memberAnalytics,
    required this.dailyStats,
    required this.tasksByCategory,
    required this.tasksByDifficulty,
  });

  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  double get averageTasksPerDay {
    final days = endDate.difference(startDate).inDays + 1;
    return days > 0 ? totalTasks / days : 0.0;
  }

  String get mostProductiveDay {
    if (dailyStats.isEmpty) return 'No data';
    final mostProductive = dailyStats
        .reduce((a, b) => a.completedTasks > b.completedTasks ? a : b);
    return _formatWeekday(mostProductive.date.weekday);
  }

  TaskCategory? get mostPopularCategory {
    if (tasksByCategory.isEmpty) return null;
    return tasksByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _formatWeekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

class MemberAnalytics {
  final String memberId;
  final String memberName;
  final int completedTasks;
  final int totalTasks;
  final int pointsEarned;
  final int streakDays;
  final Pet? pet;
  final List<TaskCompletion> recentCompletions;

  MemberAnalytics({
    required this.memberId,
    required this.memberName,
    required this.completedTasks,
    required this.totalTasks,
    required this.pointsEarned,
    required this.streakDays,
    this.pet,
    required this.recentCompletions,
  });

  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  double get averagePointsPerTask =>
      completedTasks > 0 ? pointsEarned / completedTasks : 0.0;
}

class DailyStats {
  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final int pointsEarned;

  DailyStats({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.pointsEarned,
  });

  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}

class TaskCompletion {
  final String taskId;
  final String taskTitle;
  final DateTime completedAt;
  final int pointsEarned;
  final TaskCategory category;
  final TaskDifficulty difficulty;

  TaskCompletion({
    required this.taskId,
    required this.taskTitle,
    required this.completedAt,
    required this.pointsEarned,
    required this.category,
    required this.difficulty,
  });
}

class AnalyticsService {
  // Mock data generation for demonstration
  Future<FamilyAnalytics> getFamilyAnalytics(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate, period);

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _generateMockAnalytics(familyId, startDate, endDate);
  }

  Future<List<DailyStats>> getDailyStats(
    String familyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final stats = <DailyStats>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final random = Random(currentDate.day);
      stats.add(DailyStats(
        date: currentDate,
        totalTasks: random.nextInt(8) + 2,
        completedTasks: random.nextInt(6) + 1,
        pointsEarned: (random.nextInt(40) + 10) * 5,
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return stats;
  }

  Future<Map<TaskCategory, int>> getCategoryDistribution(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final random = Random();
    return {
      for (final category in TaskCategory.values)
        category: random.nextInt(20) + 5,
    };
  }

  Future<List<MemberAnalytics>> getMemberLeaderboard(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return _generateMockMemberAnalytics();
  }

  Future<Map<String, double>> getProgressTrends(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final random = Random();
    return {
      'task_completion': 0.65 + (random.nextDouble() * 0.3),
      'points_earned': 0.78 + (random.nextDouble() * 0.2),
      'streak_maintenance': 0.45 + (random.nextDouble() * 0.4),
      'pet_happiness': 0.85 + (random.nextDouble() * 0.15),
    };
  }

  // Insights generation
  Future<List<FamilyInsight>> generateInsights(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    final analytics = await getFamilyAnalytics(familyId, period);
    final insights = <FamilyInsight>[];

    // Completion rate insight
    if (analytics.completionRate >= 0.8) {
      insights.add(FamilyInsight(
        type: InsightType.positive,
        title: 'Excellent Progress! 🌟',
        description:
            'Your family is completing ${(analytics.completionRate * 100).toInt()}% of tasks. Keep up the amazing work!',
        actionSuggestion:
            'Consider adding more challenging tasks to keep everyone engaged.',
      ));
    } else if (analytics.completionRate < 0.5) {
      insights.add(FamilyInsight(
        type: InsightType.improvement,
        title: 'Room for Growth 📈',
        description:
            'Task completion is at ${(analytics.completionRate * 100).toInt()}%. Let\'s work together to improve!',
        actionSuggestion:
            'Try breaking down larger tasks into smaller, manageable steps.',
      ));
    }

    // Most productive member
    final topMember = analytics.memberAnalytics.values
        .reduce((a, b) => a.completedTasks > b.completedTasks ? a : b);
    insights.add(FamilyInsight(
      type: InsightType.celebration,
      title: 'Star Performer! ⭐',
      description:
          '${topMember.memberName} completed ${topMember.completedTasks} tasks!',
      actionSuggestion: 'Celebrate their achievement with a special reward.',
    ));

    // Streak insights
    final memberWithLongestStreak = analytics.memberAnalytics.values
        .reduce((a, b) => a.streakDays > b.streakDays ? a : b);
    if (memberWithLongestStreak.streakDays >= 7) {
      insights.add(FamilyInsight(
        type: InsightType.streak,
        title: 'Amazing Streak! 🔥',
        description:
            '${memberWithLongestStreak.memberName} has a ${memberWithLongestStreak.streakDays}-day streak!',
        actionSuggestion: 'Help them maintain momentum with encouraging words.',
      ));
    }

    return insights;
  }

  DateTime _getStartDate(DateTime endDate, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return endDate.subtract(const Duration(days: 1));
      case AnalyticsPeriod.weekly:
        return endDate.subtract(const Duration(days: 7));
      case AnalyticsPeriod.monthly:
        return endDate.subtract(const Duration(days: 30));
      case AnalyticsPeriod.yearly:
        return endDate.subtract(const Duration(days: 365));
    }
  }

  FamilyAnalytics _generateMockAnalytics(
    String familyId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final random = Random();
    final totalTasks = random.nextInt(50) + 20;
    final completedTasks =
        (totalTasks * (0.6 + random.nextDouble() * 0.3)).round();

    return FamilyAnalytics(
      familyId: familyId,
      startDate: startDate,
      endDate: endDate,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      totalPoints: completedTasks * (random.nextInt(30) + 10),
      memberAnalytics: _generateMockMemberAnalyticsMap(),
      dailyStats: _generateMockDailyStats(startDate, endDate),
      tasksByCategory: {
        for (final category in TaskCategory.values)
          category: random.nextInt(15) + 2,
      },
      tasksByDifficulty: {
        for (final difficulty in TaskDifficulty.values)
          difficulty: random.nextInt(20) + 5,
      },
    );
  }

  Map<String, MemberAnalytics> _generateMockMemberAnalyticsMap() {
    final members = _generateMockMemberAnalytics();
    return {for (final member in members) member.memberId: member};
  }

  List<MemberAnalytics> _generateMockMemberAnalytics() {
    final names = ['Alex', 'Sam', 'Emma', 'Noah'];
    final random = Random();

    return names.map((name) {
      final completedTasks = random.nextInt(15) + 5;
      final totalTasks = completedTasks + random.nextInt(5);

      return MemberAnalytics(
        memberId: 'member_${name.toLowerCase()}',
        memberName: name,
        completedTasks: completedTasks,
        totalTasks: totalTasks,
        pointsEarned: completedTasks * (random.nextInt(20) + 10),
        streakDays: random.nextInt(14),
        recentCompletions: _generateMockCompletions(completedTasks.clamp(0, 5)),
      );
    }).toList();
  }

  List<DailyStats> _generateMockDailyStats(
      DateTime startDate, DateTime endDate) {
    final stats = <DailyStats>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final random = Random(currentDate.day);
      stats.add(DailyStats(
        date: currentDate,
        totalTasks: random.nextInt(8) + 2,
        completedTasks: random.nextInt(6) + 1,
        pointsEarned: (random.nextInt(40) + 10) * 5,
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return stats;
  }

  List<TaskCompletion> _generateMockCompletions(int count) {
    final random = Random();
    final taskTitles = [
      'Clean bedroom',
      'Do homework',
      'Help with dishes',
      'Feed the dog',
      'Read for 30 minutes',
    ];

    return List.generate(count, (index) {
      return TaskCompletion(
        taskId: 'task_$index',
        taskTitle: taskTitles[random.nextInt(taskTitles.length)],
        completedAt:
            DateTime.now().subtract(Duration(hours: random.nextInt(48))),
        pointsEarned: (random.nextInt(20) + 5) * 5,
        category:
            TaskCategory.values[random.nextInt(TaskCategory.values.length)],
        difficulty:
            TaskDifficulty.values[random.nextInt(TaskDifficulty.values.length)],
      );
    });
  }
}

enum InsightType { positive, improvement, celebration, streak, warning }

class FamilyInsight {
  final InsightType type;
  final String title;
  final String description;
  final String actionSuggestion;

  FamilyInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionSuggestion,
  });
}
