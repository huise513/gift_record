class GiftEntry {
  final int? id;
  final String giverName;
  final double amount;
  final DateTime createdAt;

  GiftEntry({
    this.id,
    required this.giverName,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'giverName': giverName,
      'amount': amount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GiftEntry.fromMap(Map<String, dynamic> map) {
    return GiftEntry(
      id: map['id'] as int?,
      giverName: map['giverName'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}