import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/models/chart_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/currency_formatter.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final List<MonthlyBar> data;

  const IncomeExpenseBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridLineColor = isDark ? AppDesignTokens.darkBorder : AppColors.border;
    final tooltipBgColor = isDark ? AppDesignTokens.darkSurfaceCard : AppColors.card;
    final labelStyle = AppTextStyles.label.copyWith(
      color: isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg,
    );

    return AspectRatio(
      aspectRatio: 2.0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => tooltipBgColor,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                final value = rod.toY;
                return BarTooltipItem(
                  '${isIncome ? 'Thu' : 'Chi'}\n${CurrencyFormatter.short(value)}',
                  AppTextStyles.monoSm.copyWith(
                    color: isIncome ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: gridLineColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[value.toInt()].month, 
                        style: labelStyle,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.short(value),
                    style: labelStyle,
                    maxLines: 1,
                    softWrap: false,
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final barWidth = data.length > 6 ? 5.0 : 10.0;
    return List.generate(data.length, (index) {
      final item = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.thu,
            color: AppColors.success,
            width: barWidth,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: item.chi,
            color: AppColors.danger,
            width: barWidth,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    });
  }
}
