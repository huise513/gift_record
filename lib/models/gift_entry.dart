class GiftEntry {
  final int? id;
  final String giverName;
  final double amount;
  final String paymentMethod;  // 支付方式：现金/微信/支付宝/银行转账
  final String? note;           // 备注
  final DateTime createdAt;

  GiftEntry({
    this.id,
    required this.giverName,
    required this.amount,
    this.paymentMethod = '现金',
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'giverName': giverName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}

// 支付方式选项
enum PaymentMethod {
  cash('现金', '💵'),
  wechat('微信', '💚'),
  alipay('支付宝', '🔵'),
  bank('银行转账', '🏦');

  final String label;
  final String emoji;

  const PaymentMethod(this.label, this.emoji);

  static List<PaymentMethod> get all => values;
}