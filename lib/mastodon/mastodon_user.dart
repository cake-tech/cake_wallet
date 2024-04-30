class MastodonUser {
  String id;
  String username;
  String profileImageUrl;
  String acct;
  String note;

  MastodonUser({
    required this.id,
    required this.username,
    required this.profileImageUrl,
    required this.acct,
    required this.note,
  });

  factory MastodonUser.fromJson(Map<String, dynamic> json) {
    return MastodonUser(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      acct: json['acct'] as String,
      note: json['note'] as String,
      profileImageUrl: json['avatar'] as String? ?? ''
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
