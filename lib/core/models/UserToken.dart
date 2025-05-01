class UserToken {
  final String accessToken;
  final String refreshToken;
  final String userId;

  UserToken({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory UserToken.fromJson(Map<String, dynamic> json) {
    return UserToken(
      accessToken: json['access_token'] ?? json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
    };
  }
}
