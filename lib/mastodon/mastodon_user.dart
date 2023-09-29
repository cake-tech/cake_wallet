class MastodonUser {
  String id;
  String username;
  String acct;
  String displayName;
  bool locked;
  bool bot;
  DateTime createdAt;
  String note;
  String url;
  String avatar;
  String avatarStatic;
  String header;
  String headerStatic;
  int followersCount;
  int followingCount;
  int statusesCount;

  MastodonUser({
    required this.id,
    required this.username,
    required this.acct,
    required this.displayName,
    required this.locked,
    required this.bot,
    required this.createdAt,
    required this.note,
    required this.url,
    required this.avatar,
    required this.avatarStatic,
    required this.header,
    required this.headerStatic,
    required this.followersCount,
    required this.followingCount,
    required this.statusesCount,
  });

  factory MastodonUser.fromJson(Map<String, dynamic> json) {
    return MastodonUser(
      id: json['id'] as String,
      username: json['username'] as String,
      acct: json['acct'] as String,
      displayName: json['display_name'] as String,
      locked: json['locked'] as bool,
      bot: json['bot'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      note: json['note'] as String,
      url: json['url'] as String,
      avatar: json['avatar'] as String,
      avatarStatic: json['avatar_static'] as String,
      header: json['header'] as String,
      headerStatic: json['header_static'] as String,
      followersCount: json['followers_count'] as int,
      followingCount: json['following_count'] as int,
      statusesCount: json['statuses_count'] as int,
    );
  }
}

class PinnedPost {
  final String id;
  final String content;

  PinnedPost({required this.id, required this.content});

  factory PinnedPost.fromJson(Map<String, dynamic> json) {
    return PinnedPost(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }
}
