import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const MonthlyChart({super.key, required this.monthlyData});

  double _interval(double maxVal) {
    if (maxVal <= 0) return 50;
    if (maxVal <= 80) return 20;
    if (maxVal <= 200) return 40;
    if (maxVal <= 500) return 100;
    if (maxVal <= 1000) return 200;
    if (maxVal <= 5000) return 1000;
    return (maxVal / 4).ceilToDouble();
  }

  LineChartBarData _line(String key, Color color) {
    final spots = List.generate(
      monthlyData.length,
      (i) => FlSpot(i.toDouble(), (monthlyData[i][key] as double)),
    );
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final maxVal = monthlyData.fold<double>(0, (prev, m) {
      final v = [
        m['income'] as double,
        m['expenses'] as double,
        m['savings'] as double,
      ].reduce((a, b) => a > b ? a : b);
      return v > prev ? v : prev;
    });

    final interval = _interval(maxVal);
    final maxY = maxVal <= 0
        ? 100.0
        : (interval * ((maxVal / interval).ceil() + 1)).toDouble();

    final year = monthlyData.isNotEmpty
        ? (monthlyData.last['month'] as DateTime).year.toString()
        : DateTime.now().year.toString();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLUSSO ANNUALE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            year,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: labelColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? const Color(0xFF252A3A) : Colors.white,
                    getTooltipItems: (spots) {
                      final labels = ['Entrate', 'Uscite', 'Risparmi'];
                      final colors = [
                        AppColors.incomeColor,
                        AppColors.expenseColor,
                        AppColors.savingColor,
                      ];
                      return spots.map((s) {
                        final idx = s.barIndex;
                        return LineTooltipItem(
                          '${labels[idx]}: €${s.y.toStringAsFixed(2)}',
                          GoogleFonts.poppins(
                              fontSize: 11, color: colors[idx]),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          '€${value.toInt()}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: textColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        final month =
                            monthlyData[idx]['month'] as DateTime;
                        return Text(
                          DateFormat('MMM', 'it_IT').format(month),
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: textColor),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line('income', AppColors.incomeColor),
                  _line('expenses', AppColors.expenseColor),
                  _line('savings', AppColors.savingColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.incomeColor, label: 'Entrate'),
              SizedBox(width: 16),
              _LegendItem(color: AppColors.expenseColor, label: 'Uscite'),
              SizedBox(width: 16),
              _LegendItem(color: AppColors.savingColor, label: 'Risparmi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11)),
      ],
    );
  }
}
