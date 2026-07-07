import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import '../widgets/monetization_widgets.dart';
import '../config/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/app_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late String _userId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _userId = SupabaseService().currentUser?.id ?? '';
    _loadAnalytics();
  }

  void _loadAnalytics() {
    Future.microtask(() {
      final provider = context.read<AnalyticsProvider>();
      provider.loadUserAnalytics(
        _userId,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Analyse'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Consumer<AnalyticsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final analytics = provider.userAnalytics;
            if (analytics == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.bar_chart,
                          size: 48, color: AppColors.grey400),
                      const SizedBox(height: 12),
                      const Text('Aucune donnée disponible',
                          style: TextStyle(color: AppColors.grey600)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildMetricsGrid(analytics),
                const SizedBox(height: 16),
                _buildConversionFunnel(analytics),
                const SizedBox(height: 16),
                _buildEngagementBreakdown(analytics),
                const SizedBox(height: 16),
                _buildRevenueBreakdown(analytics),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${DateFormat('d/M/yy').format(_startDate)} - ${DateFormat('d/M/yy').format(_endDate)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAnalytics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(AnalyticsSummary analytics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        AnalyticsMetricCard(
          title: 'Vues',
          value: analytics.totalViews.toString(),
          subtitle: 'Cette période',
          color: Colors.blue,
          icon: Icons.visibility,
        ),
        AnalyticsMetricCard(
          title: 'Clics',
          value: analytics.totalClicks.toString(),
          subtitle: 'Cette période',
          color: Colors.green,
          icon: Icons.touch_app,
        ),
        AnalyticsMetricCard(
          title: 'Conversions',
          value: analytics.totalBookings.toString(),
          subtitle: 'Réservations/achats',
          color: Colors.purple,
          icon: Icons.shopping_bag,
        ),
        AnalyticsMetricCard(
          title: 'Taux de conversion',
          value: '${analytics.conversionRate.toStringAsFixed(1)}%',
          subtitle: 'Par clic',
          color: AppColors.primary,
          icon: Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildConversionFunnel(AnalyticsSummary analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entonnoir de conversion',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFunnelStep(
              'Vues',
              analytics.totalViews.toString(),
              1.0,
              Colors.blue,
            ),
            _buildFunnelStep(
              'Clics',
              analytics.totalClicks.toString(),
              analytics.totalViews > 0
                  ? analytics.totalClicks / analytics.totalViews
                  : 0,
              Colors.green,
            ),
            _buildFunnelStep(
              'Conversions',
              analytics.totalBookings.toString(),
              analytics.totalViews > 0
                  ? analytics.totalBookings / analytics.totalViews
                  : 0,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(
    String label,
    String count,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$count (${(percent * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 24,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEngagementBreakdown(AnalyticsSummary analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition de l\'engagement',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBreakdownItem(
              'Vues',
              analytics.eventTypeBreakdown['view'] ?? 0,
              Colors.blue,
            ),
            _buildBreakdownItem(
              'Clics',
              analytics.eventTypeBreakdown['click'] ?? 0,
              Colors.green,
            ),
            _buildBreakdownItem(
              'Partages',
              analytics.eventTypeBreakdown['share'] ?? 0,
              Colors.orange,
            ),
            _buildBreakdownItem(
              'Favoris',
              analytics.eventTypeBreakdown['favorite'] ?? 0,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown(AnalyticsSummary analytics) {
    double total = 0.0;
    for (final value in analytics.revenueBySource.values) {
      total += value;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus par source',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (total == 0)
              Text(
                'Aucun revenu cette période',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              )
            else
              ...analytics.revenueBySource.entries.map((entry) {
                final percentage =
                    total > 0 ? (entry.value / total) * 100 : 0.0;
                return _buildRevenueSourceItem(
                  _formatRevenueSource(entry.key),
                  entry.value,
                  percentage,
                );
              }),
            if (total > 0) ...[
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} CFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceItem(
      String source, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(source, style: const TextStyle(fontSize: 12)),
              Text(
                '${amount.toStringAsFixed(0)} CFA',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadAnalytics();
    }
  }

  String _formatRevenueSource(String source) {
    final map = {
      'subscription': 'Abonnements',
      'featured': 'Annonces en vedette',
      'commission': 'Commissions',
      'ads': 'Publicités',
    };
    return map[source] ?? source;
  }
}
