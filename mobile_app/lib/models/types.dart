/// Enum cho phương thức thanh toán
enum PaymentMethod {
  cash('CASH', 'Tiền mặt'),
  transfer('TRANSFER', 'Chuyển khoản');

  final String value;
  final String label;
  const PaymentMethod(this.value, this.label);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Model cho sản phẩm
class Product {
  final String id;
  final String name;
  final String unit;
  final int price;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        price: (json['price'] as num).toInt(),
      );

  Product copyWith({
    String? id,
    String? name,
    String? unit,
    int? price,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        price: price ?? this.price,
      );
}

/// Model cho giao dịch
class Transaction {
  final String id;
  final int timestamp;
  final int amount;
  final PaymentMethod method;
  final String? note;

  Transaction({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.method,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'amount': amount,
        'method': method.value,
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        timestamp: json['timestamp'] as int,
        amount: (json['amount'] as num).toInt(),
        method: PaymentMethod.fromString(json['method'] as String),
        note: json['note'] as String?,
      );

  Transaction copyWith({
    String? id,
    int? timestamp,
    int? amount,
    PaymentMethod? method,
    String? note,
  }) =>
      Transaction(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        note: note ?? this.note,
      );
}

/// Model cho nhật ký kho
class StockLog {
  final String productId;
  final int startQty;
  final int addedQty;
  final int endQty;

  StockLog({
    required this.productId,
    this.startQty = 0,
    this.addedQty = 0,
    this.endQty = 0,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'startQty': startQty,
        'addedQty': addedQty,
        'endQty': endQty,
      };

  factory StockLog.fromJson(Map<String, dynamic> json) => StockLog(
        productId: json['productId'] as String,
        startQty: (json['startQty'] as num?)?.toInt() ?? 0,
        addedQty: (json['addedQty'] as num?)?.toInt() ?? 0,
        endQty: (json['endQty'] as num?)?.toInt() ?? 0,
      );

  StockLog copyWith({
    String? productId,
    int? startQty,
    int? addedQty,
    int? endQty,
  }) =>
      StockLog(
        productId: productId ?? this.productId,
        startQty: startQty ?? this.startQty,
        addedQty: addedQty ?? this.addedQty,
        endQty: endQty ?? this.endQty,
      );
}

/// Model cho phiên bán hàng hàng ngày
class DailySession {
  final String id;
  final String date;
  final bool isActive;
  final Map<String, StockLog> stockLogs;
  final List<Transaction> transactions;
  final int actualCash;
  final int actualTransfer;

  DailySession({
    required this.id,
    required this.date,
    required this.isActive,
    required this.stockLogs,
    required this.transactions,
    this.actualCash = 0,
    this.actualTransfer = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'isActive': isActive,
        'stockLogs': stockLogs.map((k, v) => MapEntry(k, v.toJson())),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'actualCash': actualCash,
        'actualTransfer': actualTransfer,
      };

  factory DailySession.fromJson(Map<String, dynamic> json) {
    final stockLogsJson = json['stockLogs'] as Map<String, dynamic>? ?? {};
    final stockLogs = stockLogsJson.map(
      (k, v) => MapEntry(k, StockLog.fromJson(v as Map<String, dynamic>)),
    );

    final transactionsJson = json['transactions'] as List<dynamic>? ?? [];
    final transactions = transactionsJson
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();

    return DailySession(
      id: json['id'] as String,
      date: json['date'] as String,
      isActive: json['isActive'] as bool,
      stockLogs: stockLogs,
      transactions: transactions,
      actualCash: (json['actualCash'] as num?)?.toInt() ?? 0,
      actualTransfer: (json['actualTransfer'] as num?)?.toInt() ?? 0,
    );
  }

  DailySession copyWith({
    String? id,
    String? date,
    bool? isActive,
    Map<String, StockLog>? stockLogs,
    List<Transaction>? transactions,
    int? actualCash,
    int? actualTransfer,
  }) =>
      DailySession(
        id: id ?? this.id,
        date: date ?? this.date,
        isActive: isActive ?? this.isActive,
        stockLogs: stockLogs ?? this.stockLogs,
        transactions: transactions ?? this.transactions,
        actualCash: actualCash ?? this.actualCash,
        actualTransfer: actualTransfer ?? this.actualTransfer,
      );
}

/// Model cho thông tin ngân hàng
class BankInfo {
  final String bankId;
  final String accountNo;
  final String accountName;

  const BankInfo({
    required this.bankId,
    required this.accountNo,
    required this.accountName,
  });

  Map<String, dynamic> toJson() => {
        'bankId': bankId,
        'accountNo': accountNo,
        'accountName': accountName,
      };

  factory BankInfo.fromJson(Map<String, dynamic> json) => BankInfo(
        bankId: json['bankId'] as String,
        accountNo: json['accountNo'] as String,
        accountName: json['accountName'] as String,
      );
}
