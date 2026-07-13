import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import 'transaction_confirm_delete_dialog.dart';

class TransactionListDesktop extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Future<void> Function(String id) onDelete;

  const TransactionListDesktop({
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


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppDesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          border: Border.all(
            color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
          ),
          boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark
                  ? AppDesignTokens.darkSurfaceCard
                  : AppDesignTokens.lightSurfaceCard,
            ),
            columnSpacing: AppDesignTokens.spaceLg,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(
                label: Text(
                  'Ngày tháng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Danh mục',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Loại',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Số tiền (VND)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Hóa đơn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Hành động',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: transactions.map((tx) {
              final isIncome = tx.type == TransactionType.income;

              return DataRow(
                cells: [
                  DataCell(Text(_formatDate(tx.date))),
                  DataCell(Text(tx.category)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.spaceSm,
                        vertical: AppDesignTokens.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppDesignTokens.success.withOpacity(0.1)
                            : AppDesignTokens.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusXs),
                      ),
                      child: Text(
                        isIncome ? 'Thu nhập' : 'Chi tiêu',
                        style: TextStyle(
                          color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${isIncome ? '+' : '-'}${_formatVnd(tx.amountVnd)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                      ),
                    ),
                  ),
                  DataCell(
                    tx.invoiceId != null && tx.scanId != null
                        ? Tooltip(
                      message: 'Xem hóa đơn',
                      child: IconButton(
                        icon: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppDesignTokens.primary,
                        ),
                        onPressed: () {
                          context.push(
                            '/transactions/receipt',
                            extra: tx,
                          );
                        },
                      ),
                    )
                        : Text(
                      'Không có',
                      style: TextStyle(
                        color: isDark
                            ? AppDesignTokens.darkTextSecondary.withOpacity(0.5)
                            : AppDesignTokens.lightTextSecondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppDesignTokens.primary),
                          tooltip: 'Sửa',
                          onPressed: () {
                            context.push('/transactions/edit', extra: tx);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppDesignTokens.error),
                          tooltip: 'Xóa',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const TransactionConfirmDeleteDialog(),
                            );
                            if (confirm == true) {
                              await onDelete(tx.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa giao dịch "${tx.category}"'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppDesignTokens.success,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
