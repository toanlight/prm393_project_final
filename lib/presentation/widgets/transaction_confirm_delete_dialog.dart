import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class TransactionConfirmDeleteDialog extends StatelessWidget {
  const TransactionConfirmDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      backgroundColor: isDark ? AppDesignTokens.darkSurface : Colors.white,
      elevation: isDark ? 24 : 8,
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: AppDesignTokens.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppDesignTokens.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spaceMd),
            Text(
              'Xác nhận xóa?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spaceSm),
            Text(
              'Hành động này không thể hoàn tác. Giao dịch này sẽ bị xóa vĩnh viễn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppDesignTokens.darkTextSecondary
                        : AppDesignTokens.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppDesignTokens.spaceLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDesignTokens.spaceMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? AppDesignTokens.darkBorder
                            : AppDesignTokens.lightBorder,
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark
                            ? AppDesignTokens.darkTextPrimary
                            : AppDesignTokens.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignTokens.spaceMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignTokens.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDesignTokens.spaceMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Xóa bỏ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
