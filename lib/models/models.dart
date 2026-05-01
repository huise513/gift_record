class Event {
  final int? id;
  final String name;       // 事件名称（婚宴/寿宴等）
  final String occasion;  // 场合类型
  final DateTime eventDate;
  final String? note;
  final DateTime createdAt;

  Event({
    this.id,
    required this.name,
    required this.occasion,
    required this.eventDate,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion,
      'eventDate': eventDate.millisecondsSinceEpoch,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      occasion: map['occasion'] as String,
      eventDate: DateTime.fromMillisecondsSinceEpoch(map['eventDate'] as int),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Event copyWith({
    int? id,
    String? name,
    String? occasion,
    DateTime? eventDate,
    String? note,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      eventDate: eventDate ?? this.eventDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Gift {
  final int? id;
  final int eventId;
  final String giverName;   // 送礼人姓名
  final double amount;      // 礼金金额
  final String? phone;      // 联系电话（可选）
  final String? note;       // 备注
  final DateTime createdAt;

  Gift({
    this.id,
    required this.eventId,
    required this.giverName,
    required this.amount,
    this.phone,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'giverName': giverName,
      'amount': amount,
      'phone': phone,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Gift.fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'] as int?,
      eventId: map['eventId'] as int,
      giverName: map['giverName'] as String,
      amount: (map['amount'] as num).toDouble(),
      phone: map['phone'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
