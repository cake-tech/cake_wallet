class TwitterUser {
  TwitterUser({required this.id, required this.username, required this.name, this.description});

  final String id;
  final String username;
  final String name;
  final String? description;

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    return TwitterUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        description: json['description'] as String?);
  }
}
