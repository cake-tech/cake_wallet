class TwitterUser {
  TwitterUser({required this.id, required this.username, required this.name, this.description,
  this.pinnedTweet});

  final String id;
  final String username;
  final String name;
  final String? description;
  final String? pinnedTweet;

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    return TwitterUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        pinnedTweet: json['pinnedTweet'] as String?);
  }
}
