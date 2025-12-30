import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/types.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final session = provider.session;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionTitle(title: 'Sổ đơn hôm nay'),
                      if (session != null && session.transactions.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'Xóa hết đơn hàng?',
                              message: 'Mẹ muốn XÓA HẾT tất cả đơn hàng hôm nay không?',
                              confirmText: 'Xóa hết',
                            );
                            if (confirmed) {
                              await provider.deleteAllTransactions();
                              if (context.mounted) {
                                showToast(context, 'Đã xóa hết đơn hàng!');
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red.shade200, width: 2),
                            ),
                          ),
                          child: const Text(
                            'XÓA HẾT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (session != null) ...[
                    // Summary cards
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Tiền mặt',
                                  amount: session.actualCash,
                                  color: AppColors.cash,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Chuyển khoản',
                                  amount: session.actualTransfer,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Transactions list
                          if (session.transactions.isEmpty)
                            const EmptyState(
                              emoji: '🛒',
                              message: 'Chưa có đơn hàng nào...',
                            )
                          else
                            ...session.transactions.map((tx) => _TransactionCard(
                                  transaction: tx,
                                  onEdit: () => _showEditDialog(context, tx),
                                  onDelete: () async {
                                    final confirmed = await showConfirmDialog(
                                      context,
                                      title: 'Xóa đơn hàng?',
                                      message: 'Mẹ muốn xóa đơn hàng này không?',
                                      confirmText: 'Xóa',
                                    );
                                    if (confirmed) {
                                      await provider.deleteTransaction(tx.id);
                                      if (context.mounted) {
                                        showToast(context, 'Đã xóa đơn hàng!');
                                      }
                                    }
                                  },
                                )),
                        ],
                      ),
                    ),
                  ] else
                    const EmptyState(
                      emoji: '📝',
                      message: 'Chưa có phiên bán hàng nào...',
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => _EditTransactionDialog(transaction: transaction),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(transaction.timestamp);
    final timeStr = DateFormat('HH:mm').format(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                transaction.method == PaymentMethod.cash ? '💵' : '💳',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(transaction.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade600,
                ),
              ),
            ],
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: Text(
                'Ghi chú: ${transaction.note}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const _EditTransactionDialog({required this.transaction});

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late PaymentMethod _method;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _method = widget.transaction.method;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(widget.transaction.timestamp);
    _time = TimeOfDay.fromDateTime(dateTime);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SỬA ĐƠN HÀNG',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(height: 24, thickness: 4, color: AppColors.primary),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền (₫)',
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Tiền mặt'),
                    selected: _method == PaymentMethod.cash,
                    onSelected: (selected) {
                      if (selected) setState(() => _method = PaymentMethod.cash);
                    },
                    selectedColor: AppColors.cash,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _method == PaymentMethod.cash ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('C.Khoản'),
                    selected: _method == PaymentMethod.transfer,
                    onSelected: (selected) {
                      if (selected) setState(() => _method = PaymentMethod.transfer);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _method == PaymentMethod.transfer ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('HỦY', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(_amountController.text);
                      if (amount == null || amount <= 0) {
                        showToast(context, 'Số tiền không hợp lệ!', isError: true);
                        return;
                      }

                      final now = DateTime.now();
                      final updatedDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _time.hour,
                        _time.minute,
                      );

                      final updatedTransaction = widget.transaction.copyWith(
                        amount: amount,
                        method: _method,
                        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                        timestamp: updatedDateTime.millisecondsSinceEpoch,
                      );

                      await context.read<AppProvider>().updateTransaction(updatedTransaction);
                      if (context.mounted) {
                        Navigator.pop(context);
                        showToast(context, 'Đã cập nhật đơn hàng!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.w900)),
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
