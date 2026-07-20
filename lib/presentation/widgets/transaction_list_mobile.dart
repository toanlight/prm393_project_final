import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/services/mock_receipt_image_store.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/transaction_provider.dart';

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

  Widget _buildMiniStatusChip(String status) {
    Color chipColor = Colors.grey.withOpacity(0.1);
    Color textColor = Colors.grey;
    String label = 'Chờ duyệt';

    if (status == 'confirmed') {
      chipColor = AppDesignTokens.success.withOpacity(0.1);
      textColor = AppDesignTokens.success;
      label = 'Đã duyệt';
    } else if (status == 'rejected') {
      chipColor = AppDesignTokens.error.withOpacity(0.1);
      textColor = AppDesignTokens.error;
      label = 'Từ chối';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showStatusApprovalSheet(BuildContext context, TransactionModel tx, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesignTokens.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phê duyệt giao dịch',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nội dung: ${tx.note.isNotEmpty ? tx.note : tx.category}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.hourglass_empty_rounded, color: Colors.grey),
                  title: const Text('Chờ duyệt (Pending)'),
                  trailing: tx.status == 'pending' ? const Icon(Icons.check, color: AppDesignTokens.primary) : null,
                  onTap: () => _updateStatus(context, tx.id, 'pending', userId),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded, color: AppDesignTokens.success),
                  title: const Text('Phê duyệt (Confirmed)'),
                  trailing: tx.status == 'confirmed' ? const Icon(Icons.check, color: AppDesignTokens.success) : null,
                  onTap: () => _updateStatus(context, tx.id, 'confirmed', userId),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: AppDesignTokens.error),
                  title: const Text('Từ chối (Rejected)'),
                  trailing: tx.status == 'rejected' ? const Icon(Icons.check, color: AppDesignTokens.error) : null,
                  onTap: () => _updateStatus(context, tx.id, 'rejected', userId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, String txId, String status, String userId) async {
    Navigator.pop(context); // Đóng BottomSheet
    try {
      await context.read<TransactionProvider>().updateTransactionStatus(
            txId,
            status,
            userId,
            invoiceRepository: context.read<InvoiceRepository>(),
          );
      if (context.mounted) {
        await context.read<InvoiceProvider>().loadInvoices(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái thành: $status'),
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
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text('Không thể tải hình ảnh', style: TextStyle(color: Colors.white)),
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
    final user = context.watch<AuthProvider>().user;
    final isChief = user?.roleId == 'chiefAccountant';

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spaceMd,
        vertical: AppDesignTokens.spaceSm,
      ),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppDesignTokens.spaceSm),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppDesignTokens.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            border: Border.all(
              color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
              width: 1,
            ),
            boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              onTap: isChief
                  ? () => _showStatusApprovalSheet(context, tx, user?.uid ?? 'chief_mock')
                  : null,
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
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
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
                            tx.note.isNotEmpty ? tx.note : tx.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _formatDate(tx.date),
                                style: TextStyle(
                                  color: isDark
                                      ? AppDesignTokens.darkTextSecondary
                                      : AppDesignTokens.lightTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (tx.note.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? AppDesignTokens.darkTextSecondary
                                            : AppDesignTokens.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ảnh hóa đơn hoặc icon (nếu có)
                    if (tx.receiptImageUrl != null || tx.invoiceId != null) ...[
                      GestureDetector(
                        onTap: () {
                          if (tx.invoiceId != null) {
                            context.push('/transactions/receipt', extra: tx);
                          } else if (tx.receiptImageUrl != null) {
                            _showImagePreview(context, tx.receiptImageUrl!);
                          }
                        },
                        child: tx.receiptImageUrl != null
                            ? Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: AppDesignTokens.spaceMd),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                  border: Border.all(
                                    color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                  child: tx.receiptImageUrl!.startsWith('mock://') && tx.scanId != null
                                      ? (MockReceiptImageStore.get(tx.scanId!) != null
                                          ? Image.memory(
                                              MockReceiptImageStore.get(tx.scanId!)!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.receipt_long_rounded, color: AppDesignTokens.primary))
                                      : Image.network(
                                          tx.receiptImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined),
                                        ),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: AppDesignTokens.spaceMd),
                                decoration: BoxDecoration(
                                  color: AppDesignTokens.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                                  border: Border.all(
                                    color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                                  ),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: AppDesignTokens.primary),
                              ),
                      ),
                    ],

                    // Số tiền & Trạng thái mini
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${isIncome ? '+' : '-'}${_formatVnd(tx.amountVnd)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildMiniStatusChip(tx.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
