import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/transaction_provider.dart';

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

  Widget _buildStatusCell(BuildContext context, TransactionModel tx, bool isDark) {
    final user = context.watch<AuthProvider>().user;
    final isChief = user?.roleId == 'chiefAccountant';

    if (isChief) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: tx.status,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: 'pending',
              child: Text('Chờ duyệt', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'confirmed',
              child: Text('Đã duyệt', style: TextStyle(fontSize: 13, color: AppDesignTokens.success)),
            ),
            DropdownMenuItem(
              value: 'rejected',
              child: Text('Từ chối', style: TextStyle(fontSize: 13, color: AppDesignTokens.error)),
            ),
          ],
          onChanged: (newValue) async {
            if (newValue != null && newValue != tx.status) {
              try {
                final userId = user?.uid ?? 'chief_mock';
                await context.read<TransactionProvider>().updateTransactionStatus(
                      tx.id,
                      newValue,
                      userId,
                      invoiceRepository: context.read<InvoiceRepository>(),
                    );
                if (context.mounted) {
                  await context.read<InvoiceProvider>().loadInvoices(userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chuyển trạng thái sang: $newValue'),
                      backgroundColor: AppDesignTokens.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: AppDesignTokens.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
        ),
      );
    }

    Color chipColor = Colors.grey.withOpacity(0.1);
    Color textColor = Colors.grey;
    String label = 'Chờ duyệt';

    if (tx.status == 'confirmed') {
      chipColor = AppDesignTokens.success.withOpacity(0.1);
      textColor = AppDesignTokens.success;
      label = 'Đã duyệt';
    } else if (tx.status == 'rejected') {
      chipColor = AppDesignTokens.error.withOpacity(0.1);
      textColor = AppDesignTokens.error;
      label = 'Từ chối';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spaceSm,
        vertical: AppDesignTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusXs),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth - 32, // trừ padding 16 * 2 của Container
                  ),
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
                          'Nội dung / Ghi chú',
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
                          'Trạng thái',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Hóa đơn',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: transactions.map((tx) {
                      final isIncome = tx.type == TransactionType.income;

                      return DataRow(
                        cells: [
                          DataCell(Text(_formatDate(tx.date))),
                          DataCell(
                            SizedBox(
                              width: constraints.maxWidth * 0.25,
                              child: Text(
                                tx.note.isNotEmpty ? tx.note : tx.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
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
                            _buildStatusCell(context, tx, isDark),
                          ),
                          DataCell(
                            tx.invoiceId != null
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
                        ],
                      );
                    }).toList(),
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
