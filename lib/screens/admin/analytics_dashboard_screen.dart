import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/admin_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _shopGrowth = [];
  List<Map<String, dynamic>> _userGrowth = [];
  bool _isLoading = true;
  String _timeRange = '30 days';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    // Load basic stats
    final stats = await _adminService.getDashboardStats();

    // Simulate growth data for now
    // In production, create a proper analytics query
    final shopGrowth = List.generate(
      7,
      (i) => {'day': i, 'count': (stats['totalShops'] ?? 0) * (i + 1) ~/ 7},
    );

    final userGrowth = List.generate(
      7,
      (i) => {'day': i, 'count': (stats['totalUsers'] ?? 0) * (i + 1) ~/ 7},
    );

    if (mounted) {
      setState(() {
        _stats = stats;
        _shopGrowth = shopGrowth;
        _userGrowth = userGrowth;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Analytics',
          actions: [
            PopupMenuButton<String>(
              initialValue: _timeRange,
              onSelected: (value) {
                setState(() => _timeRange = value);
                _loadAnalytics();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: '7 days',
                  child: Text('Last 7 days'),
                ),
                const PopupMenuItem(
                  value: '30 days',
                  child: Text('Last 30 days'),
                ),
                const PopupMenuItem(value: 'all', child: Text('All time')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(_timeRange, style: TextStyle(color: textColor)),
                    Icon(Icons.arrow_drop_down, color: textColor),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Users',
                                '${_stats['totalUsers'] ?? 0}',
                                Icons.people,
                                Colors.blue,
                                isDark,
                                textColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Total Shops',
                                '${_stats['totalShops'] ?? 0}',
                                Icons.store,
                                Colors.green,
                                isDark,
                                textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Reviews',
                                '${_stats['totalReviews'] ?? 0}',
                                Icons.star,
                                Colors.amber,
                                isDark,
                                textColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Pending',
                                '${_stats['pendingShops'] ?? 0}',
                                Icons.pending,
                                Colors.orange,
                                isDark,
                                textColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Shops Chart
                        _buildChartSection(
                          'Shop Registrations',
                          _shopGrowth,
                          Colors.green,
                          isDark,
                          textColor,
                        ),

                        const SizedBox(height: 24),

                        // Users Chart
                        _buildChartSection(
                          'User Growth',
                          _userGrowth,
                          Colors.blue,
                          isDark,
                          textColor,
                        ),

                        const SizedBox(height: 24),

                        // Shop Status Breakdown
                        Text(
                          'Shop Status',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          isDark: isDark,
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildStatusRow(
                                  'Approved',
                                  _stats['approvedShops'] ?? 0,
                                  Colors.green,
                                  textColor,
                                ),
                                const Divider(),
                                _buildStatusRow(
                                  'Pending',
                                  _stats['pendingShops'] ?? 0,
                                  Colors.orange,
                                  textColor,
                                ),
                                const Divider(),
                                _buildStatusRow(
                                  'Rejected',
                                  _stats['rejectedShops'] ?? 0,
                                  Colors.red,
                                  textColor,
                                ),
                                const Divider(),
                                _buildStatusRow(
                                  'Suspended',
                                  _stats['suspendedShops'] ?? 0,
                                  Colors.grey,
                                  textColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    List<Map<String, dynamic>> data,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          isDark: isDark,
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data
                          .map(
                            (d) => FlSpot(
                              (d['day'] as num).toDouble(),
                              (d['count'] as num).toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    int count,
    Color color,
    Color textColor,
  ) {
    final total = (_stats['totalShops'] as int? ?? 1).clamp(1, 99999);
    final percent = (count / total * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: textColor)),
          ),
          Text(
            '$count',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '($percent%)',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
