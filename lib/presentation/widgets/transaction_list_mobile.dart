import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionListMobile extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(TransactionModel transaction) onAddInvoice;

  const TransactionListMobile({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onAddInvoice,
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

  static final Map<String, String> _creatorNameCache = {};

  Widget _buildCreatorRow(BuildContext context, String userId) {
    if (_creatorNameCache.containsKey(userId)) {
      return _buildDetailRow(context, Icons.person_outline_rounded, 'Người tạo giao dịch:', _creatorNameCache[userId]!);
    }

    final userRepository = context.read<UserRepository>();
    return FutureBuilder<UserModel?>(
      future: userRepository.getUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow(context, Icons.person_outline_rounded, 'Người tạo giao dịch:', 'Đang tải...');
        }
        String displayName = userId;
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          if (user.fullName.trim().isNotEmpty) {
            displayName = user.fullName.trim();
          } else if (user.displayName.trim().isNotEmpty) {
            displayName = user.displayName.trim();
          } else if (user.email.trim().isNotEmpty) {
            displayName = user.email.trim();
          }
        }
        _creatorNameCache[userId] = displayName;
        return _buildDetailRow(context, Icons.person_outline_rounded, 'Người tạo giao dịch:', displayName);
      },
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(
      BuildContext context,
      TransactionModel tx,
      String currentUserId,
      bool canApprove,
      ) {
    final isIncome = tx.type == TransactionType.income;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInvoice = tx.invoiceId != null || tx.scanId != null || tx.receiptImageUrl != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesignTokens.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh kéo nhỏ ở đỉnh Pop-up
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Pop-up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết giao dịch',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildMiniStatusChip(tx.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Khối số tiền chính
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? AppDesignTokens.success.withOpacity(0.08)
                          : AppDesignTokens.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      border: Border.all(
                        color: isIncome
                            ? AppDesignTokens.success.withOpacity(0.2)
                            : AppDesignTokens.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                          radius: 20,
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIncome ? 'Giao dịch THU' : 'Giao dịch CHI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${isIncome ? '+' : '-'}${_formatVnd(tx.amountVnd)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Các thông tin chi tiết
                  _buildDetailRow(context, Icons.category_outlined, 'Danh mục:', tx.category),
                  const SizedBox(height: 10),
                  _buildDetailRow(context, Icons.calendar_today_outlined, 'Ngày thực hiện:', _formatDate(tx.date)),
                  const SizedBox(height: 10),
                  _buildCreatorRow(context, tx.userId),
                  if (tx.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(context, Icons.notes_rounded, 'Ghi chú:', tx.note),
                  ],

                  // Icon / Nút Hóa đơn đính kèm
                  if (hasInvoice) ...[
                    const Divider(height: 24),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (tx.invoiceId != null) {
                          context.push('/transactions/receipt', extra: tx);
                        } else if (tx.receiptImageUrl != null) {
                          _showImagePreview(context, tx.receiptImageUrl!);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppDesignTokens.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                          border: Border.all(color: AppDesignTokens.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: AppDesignTokens.primary, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hóa đơn / Chứng từ đính kèm',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'Bấm để xem chi tiết hóa đơn PDF hoặc ảnh chụp',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppDesignTokens.primary),
                          ],
                        ),
                      ),
                    ),
                  ] else if (tx.status.trim().toLowerCase() == 'rejected') ...[
                    const Divider(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppDesignTokens.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: AppDesignTokens.error.withOpacity(0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            color: AppDesignTokens.error,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Không thể thêm hóa đơn cho giao dịch đã bị từ chối.',
                              style: TextStyle(
                                color: AppDesignTokens.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await onAddInvoice(tx);
                        },
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                        ),
                        label: const Text('Thêm hóa đơn'),
                      ),
                    ),
                  ],

                  // Khối Phê duyệt (Chỉ hiển thị với Admin & Kế toán trưởng)
                  if (canApprove) ...[
                    const Divider(height: 24),
                    Text(
                      'Phê duyệt trạng thái (Admin / Kế toán trưởng)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppDesignTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus(context, tx.id, 'pending', currentUserId),
                            icon: const Icon(Icons.hourglass_empty, size: 15),
                            label: const Text('Chờ duyệt', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: BorderSide(
                                color: tx.status == 'pending' ? AppDesignTokens.primary : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(context, tx.id, 'confirmed', currentUserId),
                            icon: const Icon(Icons.check_circle_outline, size: 15),
                            label: const Text('Đã duyệt', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesignTokens.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(context, tx.id, 'rejected', currentUserId),
                            icon: const Icon(Icons.cancel_outlined, size: 15),
                            label: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesignTokens.error,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        final currentUser = context.read<AuthProvider>().user;
        await context.read<InvoiceProvider>().loadInvoices(
          userId,
          roleId: currentUser?.roleId,
          taxCode: currentUser?.taxCode,
        );
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
    final currentUserId = user?.uid ?? '';
    final roleId = user?.roleId ?? '';
    final email = user?.email.toLowerCase() ?? '';

    // Nhận diện quyền phê duyệt qua RbacPermissionService
    final canApprove = RbacPermissionService.canConfirmTransaction(user);

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
        final hasInvoice = tx.receiptImageUrl != null || tx.invoiceId != null || tx.scanId != null;

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
              onTap: () => _showTransactionDetailSheet(context, tx, currentUserId, canApprove),
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
                child: Row(
                  children: [
                    // Icon loại giao dịch (Thu/Chi)
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spaceMd),

                    // CỘT THÔNG TIN CHÍNH (Số tiền CĂN SÁT LỀ TRÁI ở dòng trên cùng)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SỐ TIỀN CĂN SÁT LỀ TRÁI (Nổi bật, Font 17px, Bold)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${isIncome ? '+' : '-'}${_formatVnd(tx.amountVnd)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: isIncome ? AppDesignTokens.success : AppDesignTokens.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // 2. Ghi chú / Tên danh mục
                          Text(
                            tx.note.isNotEmpty ? tx.note : tx.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppDesignTokens.darkTextPrimary
                                  : AppDesignTokens.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // 3. Ngày giao dịch + Danh mục Chip
                          Row(
                            children: [
                              Text(
                                _formatDate(tx.date),
                                style: TextStyle(
                                  color: isDark
                                      ? AppDesignTokens.darkTextSecondary
                                      : AppDesignTokens.lightTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              if (tx.note.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                    const SizedBox(width: 8),

                    // CỘT BÊN PHẢI (Icon Hóa đơn & Mini Status Chip)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasInvoice) ...[
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: AppDesignTokens.primary,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                        ] else if (tx.status.trim().toLowerCase() == 'rejected') ...[
                          const Tooltip(
                            message:
                            'Giao dịch đã bị từ chối, không thể thêm hóa đơn',
                            child: Icon(
                              Icons.block_rounded,
                              color: AppDesignTokens.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ] else ...[
                          IconButton(
                            tooltip: 'Thêm hóa đơn',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () => onAddInvoice(tx),
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppDesignTokens.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
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
