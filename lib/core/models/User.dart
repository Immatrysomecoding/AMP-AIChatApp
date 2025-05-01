class User {
  String email;
  Map<String, dynamic> geo;
  String id;
  List<String> roles;
  String username;

  User({
    required this.email,
    required this.geo,
    required this.id,
    required this.roles,
    required this.username,
  });
}