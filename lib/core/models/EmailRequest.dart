class EmailRequest {
  final String mainIdea;
  final String action;
  final String email;
  final Metadata metadata;

  EmailRequest({
    required this.mainIdea,
    required this.action,
    required this.email,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'mainIdea': mainIdea,
        'action': action,
        'email': email,
        'metadata': metadata.toJson(),
      };
}

class Metadata {
  final List<String> context;
  final String subject;
  final String sender;
  final String receiver;
  final Style style;
  final String language;

  Metadata({
    required this.context,
    required this.subject,
    required this.sender,
    required this.receiver,
    required this.style,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'context': context,
        'subject': subject,
        'sender': sender,
        'receiver': receiver,
        'style': style.toJson(),
        'language': language,
      };
}

class Style {
  final String length;
  final String formality;
  final String tone;

  Style({
    required this.length,
    required this.formality,
    required this.tone,
  });

  Map<String, dynamic> toJson() => {
        'length': length,
        'formality': formality,
        'tone': tone,
      };
}
