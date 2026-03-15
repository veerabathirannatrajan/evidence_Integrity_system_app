class EvidenceModel {
  final String id;
  final String caseId;
  final String fileName;
  final String fileType;
  final int    fileSize;
  final String fileHash;
  final String uploadedBy;
  final String blockchainStatus;
  final String? blockchainTxHash;
  final DateTime createdAt;
  final DateTime? anchoredAt;

  EvidenceModel({
    required this.id,
    required this.caseId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileHash,
    required this.uploadedBy,
    required this.blockchainStatus,
    this.blockchainTxHash,
    required this.createdAt,
    this.anchoredAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> j) => EvidenceModel(
    id:               j['_id'] ?? '',
    caseId:           j['caseId'] ?? '',
    fileName:         j['fileName'] ?? '',
    fileType:         j['fileType'] ?? '',
    fileSize:         j['fileSize'] ?? 0,
    fileHash:         j['fileHash'] ?? '',
    uploadedBy:       j['uploadedBy'] ?? '',
    blockchainStatus: j['blockchainStatus'] ?? 'pending',
    blockchainTxHash: j['blockchainTxHash'],
    createdAt:        DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
    anchoredAt:       j['anchoredAt'] != null ? DateTime.parse(j['anchoredAt']) : null,
  );
}