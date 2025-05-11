class EmailResponse {
  final String email;
  final int remainingUsage;
  final List<String> improvedActions;

  EmailResponse({
    required this.email,
    required this.remainingUsage,
    required this.improvedActions,
  });

  factory EmailResponse.fromJson(Map<String, dynamic> json) {
    return EmailResponse(
      email: json['email'] ?? '',
      remainingUsage: json['remainingUsage'] ?? 0,
      improvedActions: List<String>.from(json['improvedActions'] ?? []),
    );
  }
}
