class User {
  final String accessToken;
  final String refreshToken;
  final String userId;

  User({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  // Factory constructor to create a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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

  void printUserInfo() {
    print('User Information:');
    print('Access Token: $accessToken');
    print('Refresh Token: $refreshToken');
    print('User ID: $userId');
  }
}