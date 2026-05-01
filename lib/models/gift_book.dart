enum GiftBookType {
  wedding('婚宴'),
  birthday('寿宴');

  final String label;
  const GiftBookType(this.label);

  static GiftBookType fromString(String s) {
    return GiftBookType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GiftBookType.wedding,
    );
  }
}

class GiftBook {
  final int? id;
  final String name;
  final GiftBookType type;
  final DateTime createdAt;

  /// 运行时统计（不从DB查，由调用方填充）
  final int recordCount;
  final double totalAmount;

  GiftBook({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.recordCount = 0,
    this.totalAmount = 0,
  });

  GiftBook copyWith({
    int? id,
    String? name,
    GiftBookType? type,
    DateTime? createdAt,
    int? recordCount,
    double? totalAmount,
  }) {
    return GiftBook(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      recordCount: recordCount ?? this.recordCount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GiftBook.fromMap(Map<String, dynamic> map) {
    return GiftBook(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: GiftBookType.fromString(map['type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      recordCount: map['record_count'] as int? ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
