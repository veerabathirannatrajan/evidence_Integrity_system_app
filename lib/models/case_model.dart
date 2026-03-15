class CaseModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String status;
  final DateTime createdAt;

  CaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.createdAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> j) => CaseModel(
    id:          j['_id'] ?? '',
    title:       j['title'] ?? '',
    description: j['description'] ?? '',
    createdBy:   j['createdBy'] ?? '',
    status:      j['status'] ?? 'open',
    createdAt:   DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}