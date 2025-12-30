import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

/// Tiêu đề section
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 8,
          ),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          height: 1,
        ),
      ),
    );
  }
}

/// Nút bàn phím số
class KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSpecial;
  final bool isDelete;
  final bool isClear;

  const KeypadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSpecial = false,
    this.isDelete = false,
    this.isClear = false,
  });

  @override
  Widget build(BuildContext context) {
    // Màu nền
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isDelete) {
      // Nút XÓA - màu cam
      backgroundColor = Colors.orange.shade600;
      borderColor = Colors.orange.shade800;
      textColor = Colors.white;
    } else if (isClear) {
      // Nút NHẬP LẠI - màu đỏ
      backgroundColor = Colors.red.shade700;
      borderColor = Colors.red.shade900;
      textColor = Colors.white;
    } else if (isSpecial) {
      // Nút 000 - màu xanh nhạt
      backgroundColor = Colors.blue.shade100;
      borderColor = Colors.blue.shade400;
      textColor = AppColors.textPrimary;
    } else {
      // Nút số thường
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade300;
      textColor = AppColors.textPrimary;
    }
    
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: (isDelete || isClear) ? 12 : 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Format tiền tệ VND
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format số
String formatNumber(double number) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return formatter.format(number);
}

/// Toast thông báo
void showToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(milliseconds: 1500),
    ),
  );
}

/// Dialog xác nhận
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Xác nhận',
  String cancelText = 'Hủy',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Loading indicator
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final String emoji;
  final String message;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
