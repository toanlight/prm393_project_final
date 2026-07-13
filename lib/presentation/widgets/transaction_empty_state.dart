import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class TransactionEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const TransactionEmptyState({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: AppDesignTokens.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppDesignTokens.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spaceLg),
            Text(
              'Chưa có giao dịch nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spaceSm),
            Text(
              'Hãy bắt đầu ghi chép các khoản thu chi đầu tiên của bạn để theo dõi dòng tiền hiệu quả hơn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppDesignTokens.darkTextSecondary
                        : AppDesignTokens.lightTextSecondary,
                  ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: AppDesignTokens.spaceLg),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tải lại'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.spaceLg,
                    vertical: AppDesignTokens.spaceMd,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
