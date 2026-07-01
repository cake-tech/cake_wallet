class Erc20TokenInfoExplorers {
  String? contractAddress;
  String? tokenName;
  String? symbol;
  String? divisor;
  String? tokenType;
  String? totalSupply;
  String? blueCheckmark;
  String? description;
  String? website;
  String? email;
  String? blog;
  String? reddit;
  String? slack;
  String? facebook;
  String? twitter;
  String? bitcointalk;
  String? github;
  String? telegram;
  String? wechat;
  String? linkedin;
  String? discord;
  String? whitepaper;
  String? tokenPriceUSD;
  String? image;

  Erc20TokenInfoExplorers({
    this.contractAddress,
    this.tokenName,
    this.symbol,
    this.divisor,
    this.tokenType,
    this.totalSupply,
    this.blueCheckmark,
    this.description,
    this.website,
    this.email,
    this.blog,
    this.reddit,
    this.slack,
    this.facebook,
    this.twitter,
    this.bitcointalk,
    this.github,
    this.telegram,
    this.wechat,
    this.linkedin,
    this.discord,
    this.whitepaper,
    this.tokenPriceUSD,
    this.image,
  });

  Erc20TokenInfoExplorers.fromJson(Map<String, dynamic> json) {
    contractAddress = json['contractAddress'] as String?;
    tokenName = json['tokenName'] as String?;
    symbol = json['symbol'] as String?;
    divisor = json['divisor'] as String?;
    tokenType = json['tokenType'] as String?;
    totalSupply = json['totalSupply'] as String?;
    blueCheckmark = json['blueCheckmark'] as String?;
    description = json['description'] as String?;
    website = json['website'] as String?;
    email = json['email'] as String?;
    blog = json['blog'] as String?;
    reddit = json['reddit'] as String?;
    slack = json['slack'] as String?;
    facebook = json['facebook'] as String?;
    twitter = json['twitter'] as String?;
    bitcointalk = json['bitcointalk'] as String?;
    github = json['github'] as String?;
    telegram = json['telegram'] as String?;
    wechat = json['wechat'] as String?;
    linkedin = json['linkedin'] as String?;
    discord = json['discord'] as String?;
    whitepaper = json['whitepaper'] as String?;
    tokenPriceUSD = json['tokenPriceUSD'] as String?;
    image = json['image'] as String?;
  }
}
