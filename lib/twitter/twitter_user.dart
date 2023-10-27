class TwitterUser {
  TwitterUser(
      {required this.id,
      required this.username,
      required this.name,
      required this.description,
      this.pinnedTweet});

  final String id;
  final String username;
  final String name;
  final String description;
  final Tweet? pinnedTweet;

  factory TwitterUser.fromJson(Map<String, dynamic> json, [Tweet? pinnedTweet]) {
    return TwitterUser(
      id: json['data']['id'] as String,
      username: json['data']['username'] as String,
      name: json['data']['name'] as String,
      description: json['data']['description'] as String? ?? '',
      pinnedTweet: pinnedTweet,
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
