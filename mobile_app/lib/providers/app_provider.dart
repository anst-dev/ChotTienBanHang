import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/types.dart';
import '../constants.dart';

class AppProvider with ChangeNotifier {
  List<Product> _products = [];
  DailySession? _session;
  List<DailySession> _history = [];
  final Uuid _uuid = const Uuid();

  List<Product> get products => _products;
  DailySession? get session => _session;
  List<DailySession> get history => _history;

  bool get hasActiveSession => _session != null && _session!.isActive;

  AppProvider() {
    _loadData();
  }

  /// Load dữ liệu từ SharedPreferences
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load products
      final productsJson = prefs.getString(StorageKeys.products);
      if (productsJson != null) {
        final List<dynamic> decoded = jsonDecode(productsJson);
        _products = decoded.map((p) => Product.fromJson(p)).toList();
      } else {
        _products = kInitialProducts;
        await _saveProducts();
      }

      // Load current session
      final sessionJson = prefs.getString(StorageKeys.currentSession);
      if (sessionJson != null) {
        _session = DailySession.fromJson(jsonDecode(sessionJson));
      }

      // Load history
      final historyJson = prefs.getString(StorageKeys.sessionHistory);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.map((s) => DailySession.fromJson(s)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  /// Lưu products
  Future<void> _saveProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_products.map((p) => p.toJson()).toList());
      await prefs.setString(StorageKeys.products, json);
    } catch (e) {
      debugPrint('Error saving products: $e');
    }
  }

  /// Lưu session
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_session != null) {
        final json = jsonEncode(_session!.toJson());
        await prefs.setString(StorageKeys.currentSession, json);
      } else {
        await prefs.remove(StorageKeys.currentSession);
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Lưu history
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_history.map((s) => s.toJson()).toList());
      await prefs.setString(StorageKeys.sessionHistory, json);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Bắt đầu ca bán hàng mới
  Future<void> startSession() async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final stockLogs = <String, StockLog>{};
    for (final product in _products) {
      stockLogs[product.id] = StockLog(productId: product.id);
    }

    _session = DailySession(
      id: _uuid.v4(),
      date: dateKey,
      isActive: true,
      stockLogs: stockLogs,
      transactions: [],
      actualCash: 0,
      actualTransfer: 0,
    );

    await _saveSession();
    notifyListeners();
  }

  /// Cập nhật stock log
  Future<void> updateStockLog(String productId, {
    int? startQty,
    int? addedQty,
    int? endQty,
  }) async {
    if (_session == null) return;

    final currentLog = _session!.stockLogs[productId] ?? StockLog(productId: productId);
    final updatedLog = currentLog.copyWith(
      startQty: startQty ?? currentLog.startQty,
      addedQty: addedQty ?? currentLog.addedQty,
      endQty: endQty ?? currentLog.endQty,
    );

    final newStockLogs = Map<String, StockLog>.from(_session!.stockLogs);
    newStockLogs[productId] = updatedLog;

    _session = _session!.copyWith(stockLogs: newStockLogs);
    await _saveSession();
    notifyListeners();
  }

  /// Thêm giao dịch bán hàng
  Future<void> addSale({
    required int amount,
    required PaymentMethod method,
    String? note,
  }) async {
    if (_session == null || amount <= 0) return;

    final transaction = Transaction(
      id: _uuid.v4(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      amount: amount,
      method: method,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    final newTransactions = [transaction, ..._session!.transactions];
    final int newCash = method == PaymentMethod.cash
        ? _session!.actualCash + amount
        : _session!.actualCash;
    final int newTransfer = method == PaymentMethod.transfer
        ? _session!.actualTransfer + amount
        : _session!.actualTransfer;

    _session = _session!.copyWith(
      transactions: newTransactions,
      actualCash: newCash,
      actualTransfer: newTransfer,
    );

    await _saveSession();
    notifyListeners();
  }

  /// Xóa giao dịch
  Future<void> deleteTransaction(String transactionId) async {
    if (_session == null) return;

    final transaction = _session!.transactions.firstWhere(
      (t) => t.id == transactionId,
    );

    final newTransactions = _session!.transactions.where((t) => t.id != transactionId).toList();
    final int newCash = transaction.method == PaymentMethod.cash
        ? _session!.actualCash - transaction.amount
        : _session!.actualCash;
    final int newTransfer = transaction.method == PaymentMethod.transfer
        ? _session!.actualTransfer - transaction.amount
        : _session!.actualTransfer;

    _session = _session!.copyWith(
      transactions: newTransactions,
      actualCash: newCash,
      actualTransfer: newTransfer,
    );

    await _saveSession();
    notifyListeners();
  }

  /// Xóa tất cả giao dịch
  Future<void> deleteAllTransactions() async {
    if (_session == null) return;

    _session = _session!.copyWith(
      transactions: [],
      actualCash: 0,
      actualTransfer: 0,
    );

    await _saveSession();
    notifyListeners();
  }

  /// Cập nhật giao dịch
  Future<void> updateTransaction(Transaction updatedTransaction) async {
    if (_session == null) return;

    final oldTransaction = _session!.transactions.firstWhere(
      (t) => t.id == updatedTransaction.id,
    );

    final newTransactions = _session!.transactions.map((t) {
      return t.id == updatedTransaction.id ? updatedTransaction : t;
    }).toList();

    // Tính lại tổng tiền
    int newCash = _session!.actualCash;
    int newTransfer = _session!.actualTransfer;

    // Trừ tiền cũ
    if (oldTransaction.method == PaymentMethod.cash) {
      newCash -= oldTransaction.amount;
    } else {
      newTransfer -= oldTransaction.amount;
    }

    // Cộng tiền mới
    if (updatedTransaction.method == PaymentMethod.cash) {
      newCash += updatedTransaction.amount;
    } else {
      newTransfer += updatedTransaction.amount;
    }

    _session = _session!.copyWith(
      transactions: newTransactions,
      actualCash: newCash,
      actualTransfer: newTransfer,
    );

    await _saveSession();
    notifyListeners();
  }

  /// Chốt sổ và lưu vào lịch sử
  Future<void> closeSession() async {
    if (_session == null) return;

    final closedSession = _session!.copyWith(isActive: false);
    _history = [closedSession, ..._history].take(50).toList();

    await _saveHistory();
    _session = closedSession;
    await _saveSession();
    notifyListeners();
  }

  /// Thêm sản phẩm mới
  Future<void> addProduct(Product product) async {
    _products = [..._products, product];
    await _saveProducts();
    notifyListeners();
  }

  /// Cập nhật sản phẩm
  Future<void> updateProduct(Product updatedProduct) async {
    _products = _products.map((p) {
      return p.id == updatedProduct.id ? updatedProduct : p;
    }).toList();
    await _saveProducts();
    notifyListeners();
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String productId) async {
    _products = _products.where((p) => p.id != productId).toList();
    await _saveProducts();
    notifyListeners();
  }

  /// Tính doanh thu lý thuyết
  int calculateTheoreticalRevenue() {
    if (_session == null) return 0;

    int total = 0;
    for (final product in _products) {
      final log = _session!.stockLogs[product.id];
      if (log != null) {
        final sold = log.startQty + log.addedQty - log.endQty;
        if (sold > 0) {
          total += sold * product.price;
        }
      }
    }
    return total;
  }

  /// Tính chênh lệch
  int calculateDifference() {
    if (_session == null) return 0;
    final recorded = _session!.actualCash + _session!.actualTransfer;
    final theoretical = calculateTheoreticalRevenue();
    return recorded - theoretical;
  }
}
