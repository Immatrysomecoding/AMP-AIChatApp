class BotConfiguration {
  final String id;
  final String type;
  final String? accessToken;
  final String? createdBy;
  final String? updatedBy;
  final String? botName;
  final String? botToken;
  final String? redirect;

  BotConfiguration({
    required this.id,
    required this.type,
    this.accessToken,
    this.createdBy,
    this.updatedBy,
    this.botName,
    this.botToken,
    this.redirect,
  });

  factory BotConfiguration.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;

    return BotConfiguration(
      id: json['id'],
      type: json['type'],
      accessToken: json['accessToken'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      botName: metadata?['botName'],
      botToken: metadata?['botToken'],
      redirect: metadata?['redirect'],
    );
  }
}
