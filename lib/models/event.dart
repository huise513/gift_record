// Amount stored in integers (分) to avoid floating-point precision issues
// Display by dividing by 100 (元)

enum EventType {
  wedding('婚宴'),
  birthday('寿宴');

  final String label;
  const EventType(this.label);

  static EventType fromString(String s) {
    return EventType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EventType.wedding,
    );
  }
}

class Event {
  final int? id;
  final String name;
  final EventType type;
  final DateTime date;
  final int totalAmount; // in 分
  final int guestCount;

  Event({
    this.id,
    required this.name,
    required this.type,
    required this.date,
    this.totalAmount = 0,
    this.guestCount = 0,
  });

  Event copyWith({
    int? id,
    String? name,
    EventType? type,
    DateTime? date,
    int? totalAmount,
    int? guestCount,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      guestCount: guestCount ?? this.guestCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'total_amount': totalAmount,
      'guest_count': guestCount,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: EventType.fromString(map['type'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      totalAmount: map['total_amount'] as int? ?? 0,
      guestCount: map['guest_count'] as int? ?? 0,
    );
  }
}
