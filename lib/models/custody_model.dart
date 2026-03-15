class CustodyModel {
  final String id;
  final String evidenceId;
  final String fromUser;
  final String toUser;
  final String reason;
  final DateTime timestamp;

  CustodyModel({
    required this.id,
    required this.evidenceId,
    required this.fromUser,
    required this.toUser,
    required this.reason,
    required this.timestamp,
  });

  factory CustodyModel.fromJson(Map<String, dynamic> j) => CustodyModel(
    id:          j['_id'] ?? '',
    evidenceId:  j['evidenceId'] ?? '',
    fromUser:    j['fromUser'] ?? '',
    toUser:      j['toUser'] ?? '',
    reason:      j['reason'] ?? '',
    timestamp:   DateTime.parse(j['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}