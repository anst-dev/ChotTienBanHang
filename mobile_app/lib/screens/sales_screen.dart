import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/types.dart';
import '../constants.dart';
import '../widgets/common_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _amount = '';
  final TextEditingController _noteController = TextEditingController();
  
  // Giới hạn tối đa 12 ký tự (đến hàng tỷ đồng)
  static const int _maxDigits = 12;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleKeypad(String value) {
    // Haptic feedback khi nhấn nút
    HapticFeedback.lightImpact();
    
    setState(() {
      if (value == 'NHẬP LẠI') {
        // Xóa hết
        _amount = '';
      } else if (value == 'XÓA') {
        // Xóa từng ký tự cuối
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (value == '000') {
        // Thêm 000 (nếu không vượt giới hạn)
        if (_amount.isNotEmpty && _amount != '0' && _amount.length + 3 <= _maxDigits) {
          _amount += '000';
        }
      } else {
        // Thêm số (nếu không vượt giới hạn)
        if (_amount.length < _maxDigits) {
          if (_amount == '0') {
            _amount = value;
          } else {
            _amount += value;
          }
        }
      }
    });
  }

  Future<void> _handleSale(PaymentMethod method) async {
    if (_amount.isEmpty) {
      showToast(context, 'Mẹ ơi, vui lòng nhập số tiền nhé!', isError: true);
      return;
    }

    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) {
      showToast(context, 'Số tiền không hợp lệ!', isError: true);
      return;
    }

    final provider = context.read<AppProvider>();
    await provider.addSale(
      amount: amount,
      method: method,
      note: _noteController.text,
    );

    setState(() {
      _amount = '';
      _noteController.clear();
    });

    showToast(
      context,
      method == PaymentMethod.cash ? 'Đã lưu tiền mặt!' : 'Đã lưu chuyển khoản!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = _amount.isEmpty ? '0' : formatNumber(double.parse(_amount));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Display amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      '₫',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayAmount,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note input
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (VD: Chị Lan mua...)',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Keypad - 4 cột với nút XÓA tiện lợi
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.1,
                  children: [
                    '1', '2', '3', 'XÓA',
                    '4', '5', '6', '000',
                    '7', '8', '9', 'NHẬP LẠI',
                    '', '0', '', '',
                  ].map((key) {
                    if (key.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return KeypadButton(
                      label: key,
                      onPressed: () => _handleKeypad(key),
                      isDelete: key == 'XÓA',
                      isSpecial: key == '000',
                      isClear: key == 'NHẬP LẠI',
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _amount.isEmpty ? null : () => _handleSale(PaymentMethod.cash),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cash,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.cash.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'TIỀN MẶT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _amount.isEmpty ? null : () => _handleSale(PaymentMethod.transfer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'CHUYỂN KHOẢN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
