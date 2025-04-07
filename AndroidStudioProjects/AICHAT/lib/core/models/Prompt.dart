class Prompt {
  final String id;
  final String title;
  final String content;
  final String description;
  final bool isPublic;
  final bool isFavorite;
  final String? category;
  final String? language;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final String userName;

  Prompt({
    required this.id,
    required this.title,
    required this.content,
    required this.description,
    required this.isPublic,
    required this.isFavorite,
    this.category,
    this.language,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userName,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['_id'],
      title: json['title'],
      content: json['content'],
      description: json['description'],
      isPublic: json['isPublic'],
      isFavorite: json['isFavorite'],
      category: json['category'],
      language: json['language'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      userId: json['userId'],
      userName: json['userName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'description': description,
      'isPublic': isPublic,
      'isFavorite': isFavorite,
      'category': category,
      'language': language,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'userName': userName,
    };
  }
}