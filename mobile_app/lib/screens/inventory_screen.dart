import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

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
                emoji: '📦',
                message: 'Chưa có phiên bán hàng...',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionTitle(title: 'Kiểm kê hàng'),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to settings to edit products
                          DefaultTabController.of(context).animateTo(4);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SỬA MÓN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product inventory cards
                  ...products.map((product) {
                    final log = session.stockLogs[product.id];
                    return _InventoryCard(
                      product: product,
                      log: log,
                      onUpdateStart: (value) {
                        provider.updateStockLog(product.id, startQty: value);
                      },
                      onUpdateAdded: (value) {
                        provider.updateStockLog(product.id, addedQty: value);
                      },
                      onUpdateEnd: (value) {
                        provider.updateStockLog(product.id, endQty: value);
                      },
                    );
                  }),

                  const SizedBox(height: 24),

                  // Close session button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Chốt sổ?',
                          message: 'Mẹ chắc chắn muốn CHỐT SỔ không?',
                          confirmText: 'Chốt sổ',
                        );
                        if (confirmed) {
                          await provider.closeSession();
                          if (context.mounted) {
                            // Navigate to report tab
                            DefaultTabController.of(context).animateTo(3);
                            showToast(context, 'Đã chốt sổ thành công!');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'CHỐT SỔ & LƯU LỊCH SỬ',
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

class _InventoryCard extends StatelessWidget {
  final product;
  final log;
  final Function(double) onUpdateStart;
  final Function(double) onUpdateAdded;
  final Function(double) onUpdateEnd;

  const _InventoryCard({
    required this.product,
    required this.log,
    required this.onUpdateStart,
    required this.onUpdateAdded,
    required this.onUpdateEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
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
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.unit.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InventoryInput(
                  label: 'Đầu ca',
                  value: log?.startQty ?? 0,
                  color: Colors.grey,
                  onChanged: (value) => onUpdateStart(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InventoryInput(
                  label: 'Thêm',
                  value: log?.addedQty ?? 0,
                  color: AppColors.cash,
                  onChanged: (value) => onUpdateAdded(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InventoryInput(
                  label: 'Cuối ca',
                  value: log?.endQty ?? 0,
                  color: Colors.red,
                  onChanged: (value) => onUpdateEnd(value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryInput extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Function(double) onChanged;

  const _InventoryInput({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value == 0 ? '' : value.toString(),
    );

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: color.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 3),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (text) {
            final parsedValue = double.tryParse(text) ?? 0;
            onChanged(parsedValue);
          },
        ),
      ],
    );
  }
}
