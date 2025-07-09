import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/core/services/analytics_service.dart';

class RealAnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get real family analytics data from database
  Future<FamilyAnalytics> getFamilyAnalytics(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate, period);

    try {
      // Get main analytics data
      final analyticsResponse =
          await _client.rpc('get_family_analytics', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      final analytics =
          analyticsResponse.isNotEmpty ? analyticsResponse[0] : {};

      // Get daily stats for charts
      final dailyStatsResponse =
          await _client.rpc('get_daily_task_stats', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      // Get member analytics
      final memberStatsResponse =
          await _client.rpc('get_member_leaderboard', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      // Get category distribution
      final categoryResponse =
          await _client.rpc('get_task_category_distribution', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      // Convert daily stats
      final dailyStats = (dailyStatsResponse as List)
          .map((stat) => DailyStats(
                date: DateTime.parse(stat['stat_date']),
                totalTasks: stat['total_tasks'] ?? 0,
                completedTasks: stat['completed_tasks'] ?? 0,
                pointsEarned: stat['points_earned'] ?? 0,
              ))
          .toList();

      // Convert member analytics
      final memberAnalytics = <String, MemberAnalytics>{};
      for (final member in memberStatsResponse) {
        // Get recent completions for this member
        final recentCompletions = await _getRecentCompletions(
            familyId, member['member_id'], startDate, endDate);

        memberAnalytics[member['member_id']] = MemberAnalytics(
          memberId: member['member_id'],
          memberName: member['member_name'] ?? 'Unknown',
          completedTasks: member['completed_tasks'] ?? 0,
          totalTasks: member['total_tasks'] ?? 0,
          pointsEarned: member['points_earned'] ?? 0,
          streakDays: member['current_streak'] ?? 0,
          pet: null, // TODO: Load pet data if needed
          recentCompletions: recentCompletions,
        );
      }

      // Convert category distribution
      final tasksByCategory = <TaskCategory, int>{};
      for (final category in categoryResponse) {
        final categoryEnum = _parseTaskCategory(category['category']);
        if (categoryEnum != null) {
          tasksByCategory[categoryEnum] = category['task_count'] ?? 0;
        }
      }

      // Create difficulty distribution (mock for now since we don't have this data easily)
      final tasksByDifficulty = <TaskDifficulty, int>{
        TaskDifficulty.easy: 0,
        TaskDifficulty.medium: 0,
        TaskDifficulty.hard: 0,
      };

      return FamilyAnalytics(
        familyId: familyId,
        startDate: startDate,
        endDate: endDate,
        totalTasks: analytics['total_tasks'] ?? 0,
        completedTasks: analytics['completed_tasks'] ?? 0,
        totalPoints: analytics['total_points'] ?? 0,
        memberAnalytics: memberAnalytics,
        dailyStats: dailyStats,
        tasksByCategory: tasksByCategory,
        tasksByDifficulty: tasksByDifficulty,
      );
    } catch (e) {
      throw Exception('Failed to load family analytics: $e');
    }
  }

  Future<List<DailyStats>> getDailyStats(
    String familyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client.rpc('get_daily_task_stats', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return (response as List)
          .map((stat) => DailyStats(
                date: DateTime.parse(stat['stat_date']),
                totalTasks: stat['total_tasks'] ?? 0,
                completedTasks: stat['completed_tasks'] ?? 0,
                pointsEarned: stat['points_earned'] ?? 0,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to load daily stats: $e');
    }
  }

  Future<Map<TaskCategory, int>> getCategoryDistribution(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate, period);

    try {
      final response =
          await _client.rpc('get_task_category_distribution', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      final distribution = <TaskCategory, int>{};
      for (final category in response) {
        final categoryEnum = _parseTaskCategory(category['category']);
        if (categoryEnum != null) {
          distribution[categoryEnum] = category['task_count'] ?? 0;
        }
      }

      return distribution;
    } catch (e) {
      throw Exception('Failed to load category distribution: $e');
    }
  }

  Future<List<MemberAnalytics>> getMemberLeaderboard(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    final endDate = DateTime.now();
    final startDate = _getStartDate(endDate, period);

    try {
      final response = await _client.rpc('get_member_leaderboard', params: {
        'family_id_param': familyId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      final members = <MemberAnalytics>[];
      for (final member in response) {
        final recentCompletions = await _getRecentCompletions(
            familyId, member['member_id'], startDate, endDate);

        members.add(MemberAnalytics(
          memberId: member['member_id'],
          memberName: member['member_name'] ?? 'Unknown',
          completedTasks: member['completed_tasks'] ?? 0,
          totalTasks: member['total_tasks'] ?? 0,
          pointsEarned: member['points_earned'] ?? 0,
          streakDays: member['current_streak'] ?? 0,
          pet: null, // TODO: Load pet data if needed
          recentCompletions: recentCompletions,
        ));
      }

      return members;
    } catch (e) {
      throw Exception('Failed to load member leaderboard: $e');
    }
  }

  Future<List<FamilyInsight>> generateInsights(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    try {
      final analytics = await getFamilyAnalytics(familyId, period);
      final insights = <FamilyInsight>[];

      // Completion rate insight
      if (analytics.completionRate > 0.8) {
        insights.add(FamilyInsight(
          type: InsightType.positive,
          title: 'Excellent Progress!',
          description:
              'Your family completed ${(analytics.completionRate * 100).toStringAsFixed(0)}% of tasks this ${_getPeriodName(period)}.',
          actionSuggestion:
              'Keep up the amazing work! Consider adding more challenging tasks.',
        ));
      } else if (analytics.completionRate < 0.5) {
        insights.add(FamilyInsight(
          type: InsightType.improvement,
          title: 'Room for Improvement',
          description:
              'Consider setting fewer but more achievable tasks to build momentum.',
          actionSuggestion:
              'Try breaking down larger tasks into smaller, manageable steps.',
        ));
      }

      // Most productive member insight
      if (analytics.memberAnalytics.isNotEmpty) {
        final topMember = analytics.memberAnalytics.values
            .reduce((a, b) => a.completedTasks > b.completedTasks ? a : b);

        if (topMember.completedTasks > 0) {
          insights.add(FamilyInsight(
            type: InsightType.celebration,
            title: 'Top Performer!',
            description:
                '${topMember.memberName} completed ${topMember.completedTasks} tasks this ${_getPeriodName(period)}!',
            actionSuggestion:
                'Celebrate their achievement with a special reward.',
          ));
        }
      }

      // Most productive day insight
      if (analytics.dailyStats.isNotEmpty) {
        final mostProductiveDay = analytics.mostProductiveDay;
        insights.add(FamilyInsight(
          type: InsightType.streak,
          title: 'Peak Performance Day',
          description: 'Your family is most productive on $mostProductiveDay.',
          actionSuggestion: 'Plan important tasks for this day of the week.',
        ));
      }

      // Popular category insight
      if (analytics.mostPopularCategory != null) {
        insights.add(FamilyInsight(
          type: InsightType.streak,
          title: 'Popular Task Type',
          description:
              '${_getCategoryDisplayName(analytics.mostPopularCategory!)} tasks are your family\'s favorite.',
          actionSuggestion: 'Consider adding more variety to task categories.',
        ));
      }

      return insights;
    } catch (e) {
      throw Exception('Failed to generate insights: $e');
    }
  }

  Future<Map<String, double>> getProgressTrends(
    String familyId,
    AnalyticsPeriod period,
  ) async {
    try {
      final analytics = await getFamilyAnalytics(familyId, period);

      // Calculate trends based on daily stats
      if (analytics.dailyStats.length >= 2) {
        final firstHalf =
            analytics.dailyStats.take(analytics.dailyStats.length ~/ 2);
        final secondHalf =
            analytics.dailyStats.skip(analytics.dailyStats.length ~/ 2);

        final firstHalfAvg = firstHalf.isNotEmpty
            ? firstHalf.map((e) => e.completionRate).reduce((a, b) => a + b) /
                firstHalf.length
            : 0.0;

        final secondHalfAvg = secondHalf.isNotEmpty
            ? secondHalf.map((e) => e.completionRate).reduce((a, b) => a + b) /
                secondHalf.length
            : 0.0;

        final trend = secondHalfAvg - firstHalfAvg;

        return {
          'completion_rate': analytics.completionRate,
          'trend': trend,
          'average_tasks_per_day': analytics.averageTasksPerDay,
        };
      }

      return {
        'completion_rate': analytics.completionRate,
        'trend': 0.0,
        'average_tasks_per_day': analytics.averageTasksPerDay,
      };
    } catch (e) {
      throw Exception('Failed to load progress trends: $e');
    }
  }

  // Helper methods
  DateTime _getStartDate(DateTime endDate, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return DateTime(endDate.year, endDate.month, endDate.day);
      case AnalyticsPeriod.weekly:
        return endDate.subtract(Duration(days: endDate.weekday - 1));
      case AnalyticsPeriod.monthly:
        return DateTime(endDate.year, endDate.month, 1);
      case AnalyticsPeriod.yearly:
        return DateTime(endDate.year, 1, 1);
    }
  }

  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'day';
      case AnalyticsPeriod.weekly:
        return 'week';
      case AnalyticsPeriod.monthly:
        return 'month';
      case AnalyticsPeriod.yearly:
        return 'year';
    }
  }

  TaskCategory? _parseTaskCategory(String? category) {
    if (category == null) return null;

    switch (category.toLowerCase()) {
      case 'study':
        return TaskCategory.study;
      case 'work':
        return TaskCategory.work;
      case 'sport':
        return TaskCategory.sport;
      case 'family':
        return TaskCategory.family;
      case 'friends':
        return TaskCategory.friends;
      case 'other':
      default:
        return TaskCategory.other;
    }
  }

  String _getCategoryDisplayName(TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.sport:
        return 'Sport';
      case TaskCategory.family:
        return 'Family';
      case TaskCategory.friends:
        return 'Friends';
      case TaskCategory.other:
        return 'Other';
    }
  }

  Future<List<TaskCompletion>> _getRecentCompletions(
    String familyId,
    String memberId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('tasks')
          .select(
              'id, title, points, completed_at, verified_at, updated_at, category, difficulty')
          .eq('family_id', familyId)
          .eq('assigned_to_id', memberId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('completed_at', ascending: false)
          .limit(5);

      return response.map<TaskCompletion>((task) {
        final completedAt =
            task['verified_at'] ?? task['completed_at'] ?? task['updated_at'];

        return TaskCompletion(
          taskId: task['id'],
          taskTitle: task['title'] ?? 'Unknown Task',
          completedAt: DateTime.parse(completedAt),
          pointsEarned: task['points'] ?? 0,
          category: _parseTaskCategory(task['category']) ?? TaskCategory.other,
          difficulty:
              _parseTaskDifficulty(task['difficulty']) ?? TaskDifficulty.medium,
        );
      }).toList();
    } catch (e) {
      return []; // Return empty list if there's an error
    }
  }

  TaskDifficulty? _parseTaskDifficulty(String? difficulty) {
    if (difficulty == null) return null;

    switch (difficulty.toLowerCase()) {
      case 'easy':
        return TaskDifficulty.easy;
      case 'medium':
        return TaskDifficulty.medium;
      case 'hard':
        return TaskDifficulty.hard;
      default:
        return TaskDifficulty.medium;
    }
  }
}
