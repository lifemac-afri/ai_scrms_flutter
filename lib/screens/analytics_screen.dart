import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsData? _data;
  List<Map<String, dynamic>> _forecast = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final a = await ApiService.analytics();
    final f = await ApiService.demandForecast();
    if (mounted) setState(() { _data = a; _forecast = f; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget();
    if (_data == null) {
      return const EmptyState(icon: Icons.bar_chart_rounded, title: 'No Analytics', subtitle: 'Data not available');
    }
    final d = _data!;
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader(
            title: 'Analytics',
            subtitle: 'Campus resource overview',
            trailing: AiChip(label: 'Live Data'),
          ),
          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(icon: Icons.calendar_today_rounded, value: d.totalBookings, label: 'This Month', color: AppTheme.teal),
                StatCard(icon: Icons.cancel_rounded, value: d.noShows, label: 'No-Shows', color: AppTheme.red),
                StatCard(icon: Icons.people_rounded, value: d.activeUsers, label: 'Active Users', color: AppTheme.green),
                StatCard(icon: Icons.build_rounded, value: d.pendingMaintenance, label: 'Maintenance', color: AppTheme.amber),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7-day trend chart
          if (d.trend.isNotEmpty) ...[
            const SectionHeader(title: '7-Day Booking Trend'),
            AppCard(
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: AppTheme.bgCardBorder, strokeWidth: 1),
                      getDrawingVerticalLine: (_) =>
                          const FlLine(color: AppTheme.bgCardBorder, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= d.trend.length) return const SizedBox();
                            return Text(
                              d.trend[idx]['day_label'] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: d.trend.asMap().entries.map((e) => FlSpot(
                              e.key.toDouble(),
                              double.tryParse(e.value['cnt'].toString()) ?? 0,
                            )).toList(),
                        isCurved: true,
                        color: AppTheme.teal,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.teal.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // By resource type
          if (d.byType.isNotEmpty) ...[
            const SectionHeader(title: 'Bookings by Type'),
            AppCard(
              child: SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(d.byType),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: d.byType.asMap().entries.map((e) {
                  final colors = [
                    AppTheme.teal, AppTheme.purple, AppTheme.amber,
                    AppTheme.red, AppTheme.green, AppTheme.blue
                  ];
                  final c = colors[e.key % colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        '${e.value['resource_type']} (${e.value['cnt']})',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          // Top resources
          if (d.topResources.isNotEmpty) ...[
            const SizedBox(height: 8),
            const SectionHeader(title: 'Top Resources'),
            ...d.topResources.asMap().entries.map((e) {
              final r = e.value;
              final maxCnt = int.tryParse(d.topResources.first['cnt'].toString()) ?? 1;
              final cnt = int.tryParse(r['cnt'].toString()) ?? 0;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${e.key + 1}',
                            style: const TextStyle(
                                color: AppTheme.teal,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r['resource_name'] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('$cnt bookings',
                            style: const TextStyle(
                                color: AppTheme.amber, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxCnt > 0 ? cnt / maxCnt : 0,
                        backgroundColor: AppTheme.bgSurface,
                        color: AppTheme.teal,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Demand forecast
          if (_forecast.isNotEmpty) ...[
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'AI Demand Forecast',
              trailing: AiChip(label: 'Predictive'),
            ),
            AppCard(
              child: Column(
                children: _forecast.take(8).map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(f['resource_name'] ?? '',
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(f['day_of_week'] ?? '',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${f['demand_count']} bookings',
                            style: const TextStyle(
                                color: AppTheme.purple, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Map<String, dynamic>> data) {
    final colors = [
      AppTheme.teal, AppTheme.purple, AppTheme.amber,
      AppTheme.red, AppTheme.green, AppTheme.blue
    ];
    return data.asMap().entries.map((e) {
      final cnt = double.tryParse(e.value['cnt'].toString()) ?? 0;
      return PieChartSectionData(
        value: cnt,
        color: colors[e.key % colors.length],
        radius: 60,
        title: cnt.toInt().toString(),
        titleStyle: const TextStyle(
            color: AppTheme.bgDark, fontSize: 12, fontWeight: FontWeight.w700),
      );
    }).toList();
  }
}
