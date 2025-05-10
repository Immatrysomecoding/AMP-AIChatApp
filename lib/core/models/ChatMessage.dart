class ChatMessage {
  final String id;
  final String content;
  final String role;
  final List<String> files;
  final DateTime createdAt;
  final AIAssistant assistant;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    this.files = const [],
    required this.createdAt,
    required this.assistant,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content:
          json['role'] == 'user'
              ? json['query']
              : json['answer'] ?? json['content'] ?? '',
      role: json['role'] ?? '',
      files: json['files'] != null ? List<String>.from(json['files']) : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] * 1000)
              : DateTime.now(),
      assistant:
          json['assistant'] != null
              ? AIAssistant.fromJson(json['assistant'])
              : AIAssistant(id: '', model: '', name: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'files': files,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'assistant': assistant.toJson(),
    };
  }
}

class AIAssistant {
  final String id;
  final String model;
  final String name;

  AIAssistant({required this.id, required this.model, required this.name});

  factory AIAssistant.fromJson(Map<String, dynamic> json) {
    return AIAssistant(
      id: json['id'] ?? '',
      model: json['model'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'model': model, 'name': name};
  }
}

class Conversation {
  String id;
  String title;
  final DateTime createdAt;
  final AIAssistant assistant;
  List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.assistant,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Debug output
    print("Parsing conversation JSON: ${json['id']} - ${json['title']}");

    return Conversation(
      id: json['id'] ?? '',
      title: json['title'] ?? 'New Conversation',
      createdAt:
          json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                (json['createdAt'] is int
                        ? json['createdAt']
                        : int.tryParse(json['createdAt'].toString()) ??
                            (DateTime.now().millisecondsSinceEpoch ~/ 1000)) *
                    1000,
              )
              : DateTime.now(),
      assistant:
          json['assistant'] != null
              ? AIAssistant.fromJson(json['assistant'])
              : AIAssistant(id: '', model: '', name: ''),
      messages:
          json['messages'] != null
              ? List<ChatMessage>.from(
                json['messages'].map((m) => ChatMessage.fromJson(m)),
              )
              : [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'assistant': assistant.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}
