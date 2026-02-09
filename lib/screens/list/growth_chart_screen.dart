import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database.dart';
import '../../models/category.dart';

class GrowthChartScreen extends StatefulWidget {
  const GrowthChartScreen({super.key});

  @override
  State<GrowthChartScreen> createState() => _GrowthChartScreenState();
}

class _GrowthChartScreenState extends State<GrowthChartScreen> {
  String _selectedMetric = '身長';
  final _metrics = ['身長', '体重', '靴のサイズ'];

  @override
  Widget build(BuildContext context) {
    final cat = MemoryCategory.growth;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('せいちょうグラフ'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: _metrics.map((m) {
                final selected = _selectedMetric == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMetric = m),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? cat.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? cat.color : Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Memory>>(
              stream: AppDatabase.instance.watchMemoriesByCategory(cat.name),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!
                    .where((m) => m.subType == _selectedMetric)
                    .toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (records.isEmpty) {
                  return Center(
                    child: Text(
                      '$_selectedMetricの記録がまだありません',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                    ),
                  );
                }

                final spots = <FlSpot>[];
                for (var i = 0; i < records.length; i++) {
                  try {
                    final meta = jsonDecode(records[i].metadata) as Map<String, dynamic>;
                    final value = (meta['value'] as num?)?.toDouble();
                    if (value != null) {
                      spots.add(FlSpot(i.toDouble(), value));
                    }
                  } catch (e) {
                    debugPrint('Failed to parse metadata: $e');
                  }
                }

                if (spots.isEmpty) {
                  return Center(
                    child: Text('グラフ表示できるデータがありません', style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
                  );
                }

                final unit = _selectedMetric == '体重' ? 'kg' : 'cm';

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _selectedMetric == '体重' ? 5 : 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}$unit',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < records.length) {
                                final d = records[idx].createdAt;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${d.month}/${d.day}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: cat.color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(radius: 5, color: cat.color, strokeWidth: 2, strokeColor: Colors.white),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cat.color.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            return LineTooltipItem(
                              '${s.y.toStringAsFixed(1)}$unit',
                              TextStyle(color: cat.color, fontWeight: FontWeight.w700),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
