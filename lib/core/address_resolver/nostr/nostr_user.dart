
class UserMetadata {
  final String name;
  final String lnurl;
  final String email;
  final String picture;
  final String about;
  final String nip05;
  final String banner;
  final String website;

  UserMetadata({
    required this.name,
    required this.lnurl,
    required this.email,
    required this.picture,
    required this.about,
    required this.nip05,
    required this.banner,
    required this.website,
  });

  factory UserMetadata.fromJson(Map<String, dynamic> json) {
    return UserMetadata(
      name: json['name'] as String? ?? '',
      lnurl: json['lud06'] as String? ?? '',
      email: json['lud16'] as String? ?? '',
      picture: json['picture'] as String? ?? '',
      about: json['about'] as String? ?? '',
      nip05: json['nip05'] as String? ?? '',
      banner: json['banner'] as String? ?? '',
      website: json['website'] as String? ?? '',
    );
  }
}