class Prompt {
  String id;
  String title;
  String content;
  String? description;
  bool isPublic;
  bool isFavorite;
  String? category;
  String? language;
  String createdAt;
  String updatedAt;
  String userId;
  String userName;

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