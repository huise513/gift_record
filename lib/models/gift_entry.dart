class GiftEntry {
  final int? id;
  final int eventId; // 所属礼金本ID
  final String giverName;
  final double amount;
  final String paymentMethod;
  final String? note;
  final int sortOrder;
  final DateTime createdAt;

  // Sentinel object to distinguish "not provided" from "explicitly null" in copyWith
  static const Object _noteSentinel = Object();

  GiftEntry({
    this.id,
    required this.eventId,
    required this.giverName,
    required this.amount,
    this.paymentMethod = '现金',
    this.note,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GiftEntry copyWith({
    int? id,
    int? eventId,
    String? giverName,
    double? amount,
    String? paymentMethod,
    Object? note = _noteSentinel,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return GiftEntry(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      giverName: giverName ?? this.giverName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note == _noteSentinel ? this.note : note as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
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
      eventId: map['event_id'] as int,
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
  cash('现金'),
  wechat('微信');

  final String label;

  const PaymentMethod(this.label);

  static PaymentMethod fromLabel(String label) {
    return all.firstWhere(
      (m) => m.label == label,
      orElse: () => cash,
    );
  }

  static List<PaymentMethod> get all => values;
}