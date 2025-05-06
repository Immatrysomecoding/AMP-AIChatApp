class Bot {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? deletedAt;
  final String assistantName;
  final String description;
  final String instructions;
  final Map<String, dynamic> config;
  final String userId;
  final bool isDefault;
  final bool isFavorite;
  final List<String> permissions;

  Bot({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    required this.assistantName,
    required this.description,
    required this.instructions,
    required this.config,
    required this.userId,
    required this.isDefault,
    required this.isFavorite,
    required this.permissions,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedAt: json['deletedAt'],
      assistantName: json['assistantName'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      config: json['config'] ?? {},
      userId: json['userId'],
      isDefault: json['isDefault'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'assistantName': assistantName,
      'description': description,
      'instructions': instructions,
      'config': config,
      'userId': userId,
      'isDefault': isDefault,
      'isFavorite': isFavorite,
      'permissions': permissions,
    };
  }
}
