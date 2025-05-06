class Knowledge {
  final String id;
  final String knowledgeName;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? deletedAt;
  final String userId;
  final int numUnits;
  final int totalSize;

  Knowledge({
    required this.id,
    required this.knowledgeName,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    required this.userId,
    required this.numUnits,
    required this.totalSize,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      id: json['id'],
      knowledgeName: json['knowledgeName'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: json['deletedAt'],
      userId: json['userId'],
      numUnits: json['numUnits'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'knowledgeName': knowledgeName,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'userId': userId,
      'numUnits': numUnits,
      'totalSize': totalSize,
    };
  }
}
