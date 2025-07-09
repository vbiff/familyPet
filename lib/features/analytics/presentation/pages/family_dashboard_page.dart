import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/real_analytics_service.dart';
import 'package:jhonny/core/services/analytics_service.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/shared/widgets/enhanced_card.dart';
import 'package:jhonny/shared/widgets/loading_indicators.dart';

class FamilyDashboardPage extends ConsumerStatefulWidget {
  const FamilyDashboardPage({super.key});

  @override
  ConsumerState<FamilyDashboardPage> createState() =>
      _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends ConsumerState<FamilyDashboardPage>
    with TickerProviderStateMixin {
  final RealAnalyticsService _analyticsService = RealAnalyticsService();

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.weekly;
  FamilyAnalytics? _analytics;
  List<FamilyInsight>? _insights;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalytics();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Get current family ID from the family provider
      final familyState = ref.read(familyNotifierProvider);
      final familyId = familyState.family?.id;

      if (familyId == null) {
        throw Exception(
            'No family found. Please ensure you are part of a family.');
      }

      final analytics = await _analyticsService.getFamilyAnalytics(
        familyId,
        _selectedPeriod,
      );

      final insights = await _analyticsService.generateInsights(
        familyId,
        _selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _insights = insights;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changePeriod(AnalyticsPeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadAnalytics();
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'Today';
      case AnalyticsPeriod.weekly:
        return 'This Week';
      case AnalyticsPeriod.monthly:
        return 'This Month';
      case AnalyticsPeriod.yearly:
        return 'This Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch family state to reload analytics when family changes
    ref.listen(familyNotifierProvider, (previous, next) {
      if (previous?.family?.id != next.family?.id && next.family?.id != null) {
        _loadAnalytics();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
        actions: [
          PopupMenuButton<AnalyticsPeriod>(
            onSelected: _changePeriod,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AnalyticsPeriod.daily,
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: AnalyticsPeriod.weekly,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: AnalyticsPeriod.monthly,
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: AnalyticsPeriod.yearly,
                child: Text('This Year'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodLabel(_selectedPeriod)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: PulsingLoadingIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_analytics == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete some tasks to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsOverview(),
                const SizedBox(height: 24),
                if (_insights != null && _insights!.isNotEmpty) ...[
                  _buildInsightsSection(),
                  const SizedBox(height: 24),
                ],
                _buildCompletionChart(),
                const SizedBox(height: 24),
                _buildCategoryDistribution(),
                const SizedBox(height: 24),
                _buildMemberLeaderboard(),
                const SizedBox(height: 24),
                _buildProgressTrends(),
              ],
            )
                .animate()
                .slideY(
                  begin: 0.1,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 800.ms),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Tasks Completed',
            value: '${_analytics!.completedTasks}',
            subtitle: '${_analytics!.totalTasks} total',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Completion Rate',
            value: '${(_analytics!.completionRate * 100).toInt()}%',
            subtitle: _getCompletionMessage(),
            icon: Icons.trending_up,
            color: _getCompletionColor(),
          ),
        ),
      ],
    ).animate().slideX(
          begin: -0.1,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_insights == null || _insights!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...(_insights!.take(3).map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInsightCard(insight),
            ))),
      ],
    ).animate().slideY(
          begin: 0.1,
          duration: 600.ms,
          delay: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildInsightCard(FamilyInsight insight) {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getInsightColor(insight.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getInsightIcon(insight.type),
                color: _getInsightColor(insight.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (insight.actionSuggestion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 ${insight.actionSuggestion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildLineChartData(),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          duration: 700.ms,
          delay: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildCategoryDistribution() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                _buildPieChartData(),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          duration: 700.ms,
          delay: 600.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildMemberLeaderboard() {
    final members = _analytics!.memberAnalytics.values.toList()
      ..sort((a, b) => b.completedTasks.compareTo(a.completedTasks));

    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return _buildMemberCard(member, index + 1);
            }),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          duration: 700.ms,
          delay: 800.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildMemberCard(MemberAnalytics member, int rank) {
    final medal = rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: rank == 1
              ? Colors.amber.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: rank == 1
                ? Colors.amber
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(
              medal,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                member.memberName.substring(0, 1).toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.memberName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${member.completedTasks} tasks • ${member.pointsEarned} points',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (member.streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🔥 ${member.streakDays}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTrends() {
    return EnhancedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTrendItem('Task Completion', 0.78, Colors.blue),
            _buildTrendItem('Points Earned', 0.85, Colors.green),
            _buildTrendItem('Streak Maintenance', 0.62, Colors.orange),
            _buildTrendItem('Pet Happiness', 0.91, Colors.purple),
          ],
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          duration: 700.ms,
          delay: 1000.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildTrendItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${(value * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = _analytics!.dailyStats.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.completionRate);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final sections = _analytics!.tasksByCategory.entries.map((entry) {
      final index = TaskCategory.values.indexOf(entry.key);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    );
  }

  String _getCompletionMessage() {
    final rate = _analytics!.completionRate;
    if (rate >= 0.8) return 'Excellent!';
    if (rate >= 0.6) return 'Good progress';
    if (rate >= 0.4) return 'Keep going';
    return 'Needs improvement';
  }

  Color _getCompletionColor() {
    final rate = _analytics!.completionRate;
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.star;
      case InsightType.improvement:
        return Icons.trending_up;
      case InsightType.celebration:
        return Icons.celebration;
      case InsightType.streak:
        return Icons.local_fire_department;
      case InsightType.warning:
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Colors.green;
      case InsightType.improvement:
        return Colors.blue;
      case InsightType.celebration:
        return Colors.purple;
      case InsightType.streak:
        return Colors.orange;
      case InsightType.warning:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
