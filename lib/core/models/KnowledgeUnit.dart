class KnowledgeUnit {
  String createdAt;
  String createdBy;
  String updatedAt;
  String updatedBy;
  String knowledgeId;
  String userId;
  String id;
  bool status;
  String name;

  KnowledgeUnit({
    this.createdAt = "",
    this.createdBy = "",
    this.updatedAt = "",
    this.updatedBy = "",
    required this.knowledgeId,
    required this.userId,
    required this.id,
    this.status = false,
    this.name = "",
  });

  factory KnowledgeUnit.fromJson(Map<String, dynamic> json) {
    return KnowledgeUnit(
      createdAt: json['createdAt'] ?? "",
      createdBy: json['createdBy'] ?? "",
      updatedAt: json['updatedAt'] ?? "",
      updatedBy: json['updatedBy'] ?? "",
      knowledgeId: json['knowledgeId'] ?? "",
      userId: json['userId'] ?? "",
      id: json['id'] ?? "",
      status: json['status'] ?? false,
      name: json['name'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'knowledgeId': knowledgeId,
      'userId': userId,
      'id': id,
      'status': status,
      'name': name,
    };
  }
}