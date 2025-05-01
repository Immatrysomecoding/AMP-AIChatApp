class Bot {
  String id;
  String createdAt;
  String updatedAt;
  String createdBy;
  String updatedBy;
  String assistantName;
  String openAiAssistantId;
  String instructions;
  String description;
  String openAithreadId;
  String deletedAt;
  String openAivectorStoreId;
  String openAiThreadIdPlay;
  bool isDefault;
  bool isFavorite;
  String permissions;
  String userId;
  
 Bot({
    required this.id,
    required this.createdAt,
    required this.assistantName,
    required this.openAiAssistantId,
    this.instructions = "",
    this.description = "",
    this.openAithreadId = "",
    this.createdBy = "",
    this.updatedBy = "",
    this.updatedAt = "",
    this.deletedAt = "",
    this.openAivectorStoreId = "",
    this.openAiThreadIdPlay = "",
    this.isDefault = false,
    this.isFavorite = false,
    this.permissions = "",
    this.userId = "",
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
  return Bot(
    id: json['id'] ?? "",
    createdAt: json['createdAt'] ?? "",
    updatedAt: json['updatedAt'] ?? "",
    createdBy: json['createdBy'] ?? "",
    updatedBy: json['updatedBy'] ?? "",
    assistantName: json['assistantName'] ?? "",
    openAiAssistantId: json['openAiAssistantId'] ?? "", // fixed key
    instructions: json['instructions'] ?? "",
    description: json['description'] ?? "",
    openAithreadId: json['openAiThreadId'] ?? "",       // fixed key
    deletedAt: json['deletedAt'] ?? "",
    openAivectorStoreId: json['openAiVectorStoreId'] ?? "", // fixed key
    openAiThreadIdPlay: json['openAiThreadIdPlay'] ?? "",
    isDefault: json['isDefault'] ?? false,
    isFavorite: json['isFavorite'] ?? false,
    permissions: (json['permissions'] ?? "").toString(),
    userId: json['userId'] ?? "",
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'assistantName': assistantName,
      'openAiAssistantId': openAiAssistantId,
      'instructions': instructions,
      'description': description,
      'openAithreadId': openAithreadId,
      'deletedAt': deletedAt,
      'openAivectorStoreId': openAivectorStoreId,
      'openAiThreadIdPlay': openAiThreadIdPlay,
      'isDefault': isDefault,
      'isFavorite': isFavorite,
      'permissions': permissions,
      'userId': userId,
    };
  }
}