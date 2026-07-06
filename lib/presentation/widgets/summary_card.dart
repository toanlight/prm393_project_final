import 'package:flutter/material.dart';
import '../../domain/models/mock_chart_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

class KpiCard extends StatelessWidget {
  final KpiData data;

  const KpiCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IconBox
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForLabel(data.label), // The prompt didn't specify icons in KpiData, we will infer
                  color: data.color,
                  size: 18,
                ),
              ),
              const Spacer(),
              // TrendBadge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.trend,
                  style: AppTextStyles.caption.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            data.label == 'Số giao dịch' ? data.value.toString() : CurrencyFormatter.format(data.value),
            style: AppTextStyles.monoLg.copyWith(color: data.color),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    if (label == 'Tổng Thu') return Icons.trending_up_rounded;
    if (label == 'Tổng Chi') return Icons.trending_down_rounded;
    if (label == 'Số dư ròng') return Icons.account_balance_wallet_outlined;
    return Icons.receipt_long_outlined;
  }
}
