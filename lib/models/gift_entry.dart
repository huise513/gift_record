class GiftEntry {
  final int? id;
  final String giverName;
  final double amount;
  final String paymentMethod;
  final String? note;
  final int sortOrder;
  final DateTime createdAt;

  GiftEntry({
    this.id,
    required this.giverName,
    required this.amount,
    this.paymentMethod = '现金',
    this.note,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GiftEntry copyWith({
    int? id,
    String? giverName,
    double? amount,
    String? paymentMethod,
    String? note,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return GiftEntry(
      id: id ?? this.id,
      giverName: giverName ?? this.giverName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'giverName': giverName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GiftEntry.fromMap(Map<String, dynamic> map) {
    return GiftEntry(
      id: map['id'] as int?,
      giverName: map['giverName'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? '现金',
      note: map['note'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}

enum PaymentMethod {
  cash('现金', '💵'),
  wechat('微信', '💚'),
  alipay('支付宝', '🔵'),
  bank('银行转账', '🏦');

  final String label;
  final String emoji;

  const PaymentMethod(this.label, this.emoji);

  static PaymentMethod fromLabel(String label) {
    return all.firstWhere(
      (m) => m.label == label,
      orElse: () => cash,
    );
  }

  static List<PaymentMethod> get all => values;
}