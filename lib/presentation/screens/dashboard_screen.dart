import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/models/mock_chart_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/income_expense_bar_chart.dart';
import '../widgets/income_expense_line_chart.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilter = 'Tháng này';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.sp24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.sp24),
            AppResponsiveLayout(
              mobile: _buildMobileLayout(context),
              desktop: _buildDesktopLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng quan', style: AppTextStyles.h1),
        const SizedBox(height: AppTheme.sp4),
        Text('Tháng 6/2026 - cập nhật lúc 10:32 SA', style: AppTextStyles.caption),
        const SizedBox(height: AppTheme.sp24),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Tháng này', 'Tháng trước', 'Quý này', 'Toàn bộ'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.sp8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: AppColors.border),
                ),
                child: Text(
                  filter,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? AppColors.primaryFg : AppColors.mutedFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards Row
        Row(
          children: kpiCards.asMap().entries.map((entry) {
            int idx = entry.key;
            KpiData metric = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx == kpiCards.length - 1 ? 0 : AppTheme.sp12,
                ),
                child: KpiCard(data: metric)
                    .animate(delay: (idx * 80).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.sp24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildBarChartCard(context)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
              ),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                flex: 1,
                child: _buildPieChartCard(context)
                    .animate(delay: 280.ms)
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.sp24),
        _buildLineChartCard(context)
            .animate(delay: 360.ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards Column
        ...kpiCards.asMap().entries.map((entry) {
            int idx = entry.key;
            KpiData metric = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp12),
            child: KpiCard(data: metric)
                .animate(delay: (idx * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          );
        }).toList(),
        _buildBarChartCard(context)
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
        const SizedBox(height: AppTheme.sp12),
        _buildPieChartCard(context)
            .animate(delay: 280.ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
        const SizedBox(height: AppTheme.sp12),
        _buildLineChartCard(context)
            .animate(delay: 360.ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thu & Chi theo tháng', style: AppTextStyles.h2),
                  const SizedBox(height: AppTheme.sp4),
                  Text('Đơn vị: triệu VND', style: AppTextStyles.caption),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot(AppColors.success, 'Thu'),
                  const SizedBox(width: AppTheme.sp16),
                  _buildLegendDot(AppColors.danger, 'Chi'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp24),
          IncomeExpenseBarChart(data: monthlyData),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cơ cấu chi phí', style: AppTextStyles.h2),
          const SizedBox(height: AppTheme.sp4),
          Text('Tháng 6/2026', style: AppTextStyles.caption),
          const SizedBox(height: AppTheme.sp24),
          SizedBox(
            height: 180,
            child: ExpensePieChart(data: spendingData),
          ),
          const SizedBox(height: AppTheme.sp24),
          _buildPieLegend(),
        ],
      ),
    );
  }

  Widget _buildPieLegend() {
    return Column(
      children: spendingData.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                  Text(e.name, style: AppTextStyles.caption),
                ],
              ),
              Text(
                '${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 1)}tr',
                style: AppTextStyles.monoSm.copyWith(color: e.color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChartCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xu hướng số dư ròng', style: AppTextStyles.h2),
                  const SizedBox(height: AppTheme.sp4),
                  Text('1-12/6/2026 • Đơn vị: triệu VND', style: AppTextStyles.caption),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Text(
                  '+12.3% so với kỳ trước',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp24),
          IncomeExpenseLineChart(data: trendData),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.sp4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
