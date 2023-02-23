class TwitterUser {
  TwitterUser(
      {required this.id,
      required this.username,
      required this.name,
      required this.description,
      this.tweets});

  final String id;
  final String username;
  final String name;
  final String description;
  final List<Tweet>? tweets;

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    return TwitterUser(
      id: json['data']['id'] as String,
      username: json['data']['username'] as String,
      name: json['data']['name'] as String,
      description: json['data']['description'] as String? ?? '',
      tweets: json['includes'] != null
          ? List.from(json['includes']['tweets'] as List)
              .map((e) => Tweet.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class Tweet {
  Tweet({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }
}
