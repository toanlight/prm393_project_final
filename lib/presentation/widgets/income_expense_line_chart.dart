import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/models/chart_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/currency_formatter.dart';

class _AxisConfig {
  final double maxY;
  final double interval;
  _AxisConfig(this.maxY, this.interval);
}

_AxisConfig _calculateAxisConfig(double maxVal) {
  if (maxVal <= 0) return _AxisConfig(100, 25);

  double targetMax = maxVal * 1.25;
  double rawInterval = targetMax / 4;

  double exponent = (rawInterval <= 0) ? 0 : (log(rawInterval) / ln10).floorToDouble();
  double magnitude = pow(10, exponent).toDouble();
  double residual = rawInterval / magnitude;

  double niceInterval;
  if (residual < 1.5) {
    niceInterval = 1 * magnitude;
  } else if (residual < 3) {
    niceInterval = 2 * magnitude;
  } else if (residual < 7) {
    niceInterval = 5 * magnitude;
  } else {
    niceInterval = 10 * magnitude;
  }

  double maxY = (targetMax / niceInterval).ceil() * niceInterval;
  if (maxY < maxVal * 1.15) {
    maxY += niceInterval;
  }

  return _AxisConfig(maxY, niceInterval);
}

class IncomeExpenseLineChart extends StatelessWidget {
  final List<TrendPoint> data;

  const IncomeExpenseLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridLineColor = isDark ? AppDesignTokens.darkBorder : AppColors.border;
    final tooltipBgColor = isDark ? AppDesignTokens.darkSurfaceCard : AppColors.card;
    final dotStrokeColor = isDark ? AppDesignTokens.darkSurface : AppColors.card;
    final labelStyle = AppTextStyles.label.copyWith(
      color: isDark ? AppDesignTokens.darkTextSecondary : AppColors.mutedFg,
    );

    double maxVal = 0;
    for (var item in data) {
      if (item.balance.abs() > maxVal) maxVal = item.balance.abs();
    }
    final axisConfig = _calculateAxisConfig(maxVal);

    return AspectRatio(
      aspectRatio: 3.5,
      child: LineChart(
        LineChartData(
          maxY: axisConfig.maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => tooltipBgColor,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    CurrencyFormatter.short(spot.y),
                    AppTextStyles.monoSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisConfig.interval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: gridLineColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[value.toInt()].date, 
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
                interval: axisConfig.interval,
                reservedSize: 52,
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
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: dotStrokeColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index].balance);
    });
  }
}
