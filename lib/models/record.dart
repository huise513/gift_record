// Amount stored in integers (分) to avoid floating-point precision issues
// Display by dividing by 100 (元)

class Record {
  final int? id;
  final int eventId;
  final String guestName;
  final int amount; // in 分 (cents)
  final DateTime createdTime;

  Record({
    this.id,
    required this.eventId,
    required this.guestName,
    required this.amount,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now();

  Record copyWith({
    int? id,
    int? eventId,
    String? guestName,
    int? amount,
    DateTime? createdTime,
  }) {
    return Record(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      guestName: guestName ?? this.guestName,
      amount: amount ?? this.amount,
      createdTime: createdTime ?? this.createdTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'event_id': eventId,
      'guest_name': guestName,
      'amount': amount,
      'created_time': createdTime.millisecondsSinceEpoch,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      guestName: map['guest_name'] as String,
      amount: map['amount'] as int,
      createdTime: DateTime.fromMillisecondsSinceEpoch(map['created_time'] as int),
    );
  }
}
