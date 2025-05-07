class KnowledgeUnit {
  final String id;
  final String knowledgeId;
  final String? createdBy;
  final String? updatedBy;
  final String? deletedAt;
  final String userId;
  final String createdAt;
  final String updatedAt;
  final bool status;
  final String name;
  final double size;
  final String type;
  final String datasourceId;
  final Map<String, dynamic> metadata;

  KnowledgeUnit({
    required this.id,
    required this.knowledgeId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.name,
    required this.size,
    required this.type,
    required this.datasourceId,
    required this.metadata,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
  });

  factory KnowledgeUnit.fromJson(Map<String, dynamic> json) {
    return KnowledgeUnit(
      id: json['id'] ?? '',
      knowledgeId: json['knowledgeId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: json['deletedAt'],
      status: json['status'] ?? false,
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      datasourceId: json['datasourceId'] ?? '',
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'knowledgeId': knowledgeId,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'status': status,
      'name': name,
      'size': size,
      'type': type,
      'datasourceId': datasourceId,
      'metadata': metadata,
    };
  }
}
