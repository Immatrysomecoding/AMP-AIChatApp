class UserToken {
  final String accessToken;
  final String refreshToken;
  final String userId;

  UserToken({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  // Factory constructor to create a User from a JSON map
  factory UserToken.fromJson(Map<String, dynamic> json) {
    return UserToken(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      userId: json['user_id'],
    );
  }

  // Method to convert a User instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
    };
  }
}