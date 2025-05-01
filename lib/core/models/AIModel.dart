class AIModel {
  final String id;
  final String model; // The backend model identifier like 'dify', 'knowledge-base', etc.
  final String name;
  final String? description;
  final String? iconUrl;
  bool isDefault;

  AIModel({
    required this.id,
    required this.model,
    required this.name,
    this.description,
    this.iconUrl,
    this.isDefault = false,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] ?? '',
      model: json['model'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['iconUrl'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'isDefault': isDefault,
    };
  }
}
