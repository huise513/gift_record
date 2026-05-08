import 'package:flutter/services.dart';

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

  /// 格式化金额（截断不四舍五入）：整数不显示小数，最多两位小数
  String get amountDisplay {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    // 截断而非四舍五入
    final truncated = (amount * 100).floor() / 100;
    return truncated.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  /// 格式化总额（截断不四舍五入），如 ¥123 或 ¥123.5 或 ¥123.55
  String get totalDisplay {
    if (amount == amount.roundToDouble()) {
      return '¥${amount.toInt()}';
    }
    final truncated = (amount * 100).floor() / 100;
    final s = truncated.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '¥$s';
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

/// 金额输入格式化器：最多9位整数+最多2位小数，输入超限或格式无效时拒绝输入
class DecimalAmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    // 允许空
    if (text.isEmpty) return newValue;
    // 允许最多9位整数+最多2位小数的格式（小数点后可以无数字，如 "1."）
    if (RegExp(r'^(\d{0,9}(\.\d{0,2})?)$').hasMatch(text)) {
      return newValue;
    }
    // 拒绝无效输入，保留原值
    return oldValue;
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
