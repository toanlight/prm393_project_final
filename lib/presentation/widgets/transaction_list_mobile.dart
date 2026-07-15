import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import 'transaction_confirm_delete_dialog.dart';

class TransactionListMobile extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Future<void> Function(String id) onDelete;

  const TransactionListMobile({
    super.key,
    required this.transactions,
    required this.onDelete,
  });

  String _formatVnd(int amount) {
    final cleanString = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = cleanString.length - 1; i >= 0; i--) {
      buffer.write(cleanString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDesignTokens.spaceMd),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Không thể tải hình ảnh',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spaceMd,
        vertical: AppDesignTokens.spaceSm,
      ),
      itemCount: transactions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDesignTokens.spaceSm),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;

        return Dismissible(
          key: Key('tx_${tx.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const TransactionConfirmDeleteDialog(),
            );
          },
          onDismissed: (direction) {
            onDelete(tx.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa giao dịch "${tx.category}"'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppDesignTokens.success,
              ),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spaceLg,
            ),
            decoration: BoxDecoration(
              color: AppDesignTokens.error,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xóa giao dịch',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppDesignTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              border: Border.all(
                color: isDark
                    ? AppDesignTokens.darkBorder
                    : AppDesignTokens.lightBorder,
                width: 1,
              ),
              boxShadow: isDark
                  ? AppDesignTokens.darkShadow
                  : AppDesignTokens.lightShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                onTap: () {
                  context.push('/transactions/edit', extra: tx);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                  child: Row(
                    children: [
                      // Icon loại giao dịch
                      Container(
                        padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? AppDesignTokens.success.withOpacity(0.1)
                              : AppDesignTokens.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isIncome
                              ? AppDesignTokens.success
                              : AppDesignTokens.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.spaceMd),

                      // Thông tin Giao dịch
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(tx.date),
                              style: TextStyle(
                                color: isDark
                                    ? AppDesignTokens.darkTextSecondary
                                    : AppDesignTokens.lightTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ảnh hóa đơn thu nhỏ (nếu có)
                      if (tx.receiptImageUrl != null) ...[
                        GestureDetector(
                          onTap: () =>
                              _showImagePreview(context, tx.receiptImageUrl!),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(
                              right: AppDesignTokens.spaceMd,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppDesignTokens.darkBorder
                                    : AppDesignTokens.lightBorder,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(tx.receiptImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Số tiền
                      Text(
                        '${isIncome ? '+' : '-'}${_formatVnd(tx.amountVnd)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIncome
                              ? AppDesignTokens.success
                              : AppDesignTokens.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
