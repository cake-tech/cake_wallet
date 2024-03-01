class TwitterUser {
  TwitterUser(
      {required this.id,
      required this.username,
      required this.name,
      required this.description,
      required this.profileImageUrl,
      this.pinnedTweet});

  final String id;
  final String username;
  final String name;
  final String description;
  final String profileImageUrl;
  final Tweet? pinnedTweet;

  factory TwitterUser.fromJson(Map<String, dynamic> json, [Tweet? pinnedTweet]) {
    final profileImageUrl = json['data']['profile_image_url'] as String? ?? '';
    final scaledProfileImageUrl = profileImageUrl.replaceFirst('normal', '200x200');
    return TwitterUser(
      id: json['data']['id'] as String,
      username: json['data']['username'] as String? ?? '',
      name: json['data']['name'] as String,
      description: json['data']['description'] as String? ?? '',
      profileImageUrl: scaledProfileImageUrl,
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
