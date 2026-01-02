import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/types.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final session = provider.session;
            final products = provider.products;

            if (session == null) {
              return const EmptyState(
                emoji: '📊',
                message: 'Chưa có dữ liệu báo cáo...',
              );
            }

            final theoreticalRevenue = provider.calculateTheoreticalRevenue();
            final recordedTotal = session.actualCash + session.actualTransfer;
            final difference = provider.calculateDifference();

            // Calculate sold items
            final soldItems = products.map((product) {
              final log = session.stockLogs[product.id];
              if (log == null) return null;
              final sold = log.startQty + log.addedQty - log.endQty;
              final revenue = sold > 0 ? sold * product.price : 0;
              return {
                'product': product,
                'log': log,
                'sold': sold > 0 ? sold : 0,
                'revenue': revenue,
              };
            }).where((item) => item != null).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Kết quả hôm nay'),
                  const SizedBox(height: 16),

                  // Summary cards
                  _SummaryCard(
                    label: 'Thực thu Tiền mặt',
                    amount: session.actualCash,
                    color: AppColors.cash,
                    borderColor: AppColors.cashDark,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Thực thu Chuyển khoản',
                    amount: session.actualTransfer,
                    color: AppColors.primary,
                    borderColor: AppColors.primaryDark,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    label: 'Doanh thu lý thuyết',
                    amount: theoreticalRevenue,
                    color: Colors.grey.shade700,
                    borderColor: Colors.grey.shade500,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 24),

                  // Difference card
                  _DifferenceCard(
                    difference: difference,
                    recordedTotal: recordedTotal,
                    theoreticalRevenue: theoreticalRevenue,
                  ),
                  const SizedBox(height: 24),

                  // Sold items detail
                  const SectionTitle(title: 'Chi tiết hàng đã bán'),
                  const SizedBox(height: 16),

                  ...soldItems.map((item) => _SoldItemCard(
                        product: item!['product'] as Product,
                        log: item['log'] as StockLog,
                        sold: (item['sold'] as num).toInt(),
                        revenue: (item['revenue'] as num).toInt(),
                      )),

                  const SizedBox(height: 24),

                  // New session button
                  if (!session.isActive)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Làm ca mới?',
                            message: 'Xóa ca cũ & Làm ca mới?',
                            confirmText: 'Làm ca mới',
                          );
                          if (confirmed) {
                            await provider.startSession();
                            if (context.mounted) {
                              // Navigate to inventory tab
                              HomeScreen.navigatorKey.currentState?.navigateToTab(2);
                              showToast(context, 'Đã bắt đầu ca mới!');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'XÓA CA CŨ & LÀM CA MỚI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final Color borderColor;
  final Color? backgroundColor;
  final Color? textColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.borderColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            border: Border(
              left: BorderSide(color: borderColor, width: 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(amount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor ?? color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  final int difference;
  final int recordedTotal;
  final int theoreticalRevenue;

  const _DifferenceCard({
    required this.difference,
    required this.recordedTotal,
    required this.theoreticalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final isMatch = difference == 0;
    final isOver = difference > 0;

    final bgColor = isMatch
        ? Colors.green.shade50
        : isOver
            ? Colors.blue.shade50
            : Colors.red.shade50;
    final borderColor = isMatch
        ? AppColors.success
        : isOver
            ? AppColors.primaryLight
            : AppColors.error;
    final textColor = isMatch
        ? AppColors.cashDark
        : isOver
            ? AppColors.primaryDark
            : Colors.red.shade900;
    final badgeColor = isMatch
        ? AppColors.cash
        : isOver
            ? AppColors.primary
            : AppColors.error;
    final message = isMatch
        ? 'Mẹ giỏi quá!'
        : isOver
            ? 'Thừa tiền mẹ ơi'
            : 'Thiếu tiền rồi';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CHÊNH LỆCH THỪA/THIẾU',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMatch ? 'KHỚP SỔ!' : formatCurrency(difference.abs()),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              message.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldItemCard extends StatelessWidget {
  final Product product;
  final StockLog log;
  final int sold;
  final int revenue;

  const _SoldItemCard({
    required this.product,
    required this.log,
    required this.sold,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(product.price)} / ${product.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'THÀNH TIỀN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatCurrency(revenue),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cashDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 3),
                bottom: BorderSide(color: Colors.grey.shade100, width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StockInfo(
                    label: 'Đầu ca',
                    value: log.startQty,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _StockInfo(
                    label: 'Nhập',
                    value: log.addedQty,
                    color: AppColors.cash,
                    showPlus: true,
                  ),
                ),
                Expanded(
                  child: _StockInfo(
                    label: 'Cuối ca',
                    value: log.endQty,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SỐ LƯỢNG BÁN ĐƯỢC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      sold.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.unit.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockInfo extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool showPlus;

  const _StockInfo({
    required this.label,
    required this.value,
    required this.color,
    this.showPlus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          showPlus && value > 0 ? '+$value' : value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
