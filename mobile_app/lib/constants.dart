import 'package:flutter/material.dart';
import 'models/types.dart';

/// Danh sách sản phẩm mặc định
const List<Map<String, dynamic>> kInitialProductsData = [
  {
    'id': '1',
    'name': 'Bia Sài Gòn (Két)',
    'unit': 'Két',
    'price': 250000.0
  },
  {
    'id': '2',
    'name': 'Nước ngọt (Thùng)',
    'unit': 'Thùng',
    'price': 180000.0
  },
  {
    'id': '3',
    'name': 'Gạo ST25 (Túi 5kg)',
    'unit': 'Túi',
    'price': 160000.0
  },
];

List<Product> get kInitialProducts =>
    kInitialProductsData.map((data) => Product.fromJson(data)).toList();

/// Thông tin ngân hàng mặc định
const BankInfo kDefaultBankInfo = BankInfo(
  bankId: 'MB',
  accountNo: '0982094668',
  accountName: 'NGUYEN DANG HIEU',
);

/// Màu sắc ứng dụng
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1E3A8A); // blue-900
  static const Color primaryLight = Color(0xFF3B82F6); // blue-500
  static const Color primaryDark = Color(0xFF1E40AF); // blue-800

  // Cash colors
  static const Color cash = Color(0xFF047857); // emerald-700
  static const Color cashLight = Color(0xFF10B981); // emerald-500
  static const Color cashDark = Color(0xFF065F46); // emerald-800

  // Transfer colors
  static const Color transfer = Color(0xFF1E3A8A); // blue-900
  static const Color transferLight = Color(0xFF3B82F6); // blue-500

  // Status colors
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color error = Color(0xFFDC2626); // red-600
  static const Color warning = Color(0xFFF59E0B); // amber-500

  // Neutral colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFB); // gray-50
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color border = Color(0xFFE5E7EB); // gray-200
}

/// Keys cho SharedPreferences
class StorageKeys {
  static const String products = 'products';
  static const String currentSession = 'current_session';
  static const String sessionHistory = 'session_history';
}
