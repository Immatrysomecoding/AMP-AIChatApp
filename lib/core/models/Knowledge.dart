class Knowledge {
  final String knowledgeName;
  final String description;
  final String createdAt;
  final String createdBy;
  final String updatedAt;
  final String updatedBy;
  final String deletedAt;
  final String id;
  final String userId;
  final int numUnits;
  final int totalSize;

  Knowledge({
    required this.knowledgeName,
    this.description = "",
    this.createdAt = "",
    this.updatedAt = "",
    required this.id,
    this.createdBy = "",
    this.updatedBy = "",
    this.deletedAt = "",
    required this.userId,
    this.numUnits = 0,
    this.totalSize = 0,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      knowledgeName: json['knowledgeName'] ?? "",
      description: json['description'] ?? "",
      createdAt: json['createdAt'] ?? "",
      updatedAt: json['updatedAt'] ?? "",
      id: json['id'] ?? "",
      createdBy: json['createdBy'] ?? "",
      updatedBy: json['updatedBy'] ?? "",
      deletedAt: json['deletedAt'] ?? "",
      userId: json['userId'] ?? "",
      numUnits: json['numUnits'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'knowledgeName': knowledgeName,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'id': id, // ✅ corrected key
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'userId': userId,
      'numUnits': numUnits,
      'totalSize': totalSize,
    };
  }
}
