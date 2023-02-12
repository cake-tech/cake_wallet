class TwitterUser {
  TwitterUser({
    required this.data,
    this.includes,
  });

  late final Data data;
  late final Includes? includes;

  TwitterUser.fromJson(Map<String, dynamic> json) {
    data = Data.fromJson(json['data'] as Map<String, dynamic>);
    includes = json['includes'] != null
        ? Includes.fromJson(json['includes'] as Map<String, dynamic>)
        : null;
  }
}

class Data {
  Data({
    required this.name,
    required this.id,
    required this.pinnedTweetId,
    required this.description,
    required this.username,
  });

  late final String name;
  late final String id;
  late final String? pinnedTweetId;
  late final String description;
  late final String username;

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String;
    id = json['id'] as String;
    pinnedTweetId = json['pinned_tweet_id'] as String?;
    description = json['description'] as String;
    username = json['username'] as String;
  }
}

class Includes {
  Includes({
    required this.tweets,
  });

  late final List<Tweets> tweets;

  Includes.fromJson(Map<String, dynamic> json) {
    tweets = List.from(json['tweets'] as Iterable<dynamic>)
        .map((e) => Tweets.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class Tweets {
  Tweets({
    required this.editHistoryTweetIds,
    required this.id,
    required this.text,
  });

  late final List<String> editHistoryTweetIds;
  late final String id;
  late final String text;

  Tweets.fromJson(Map<String, dynamic> json) {
    editHistoryTweetIds =
        List.castFrom<dynamic, String>(json['edit_history_tweet_ids'] as List<dynamic>);
    id = json['id'] as String;
    text = json['text'] as String;
  }
}
