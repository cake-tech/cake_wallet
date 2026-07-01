class Erc20TokenInfoMoralis {
  String? address;
  String? addressLabel;
  String? name;
  String? symbol;
  String? decimals;
  String? logo;
  String? logoHash;
  String? thumbnail;
  String? totalSupply;
  String? totalSupplyFormatted;
  String? fullyDilutedValuation;
  String? blockNumber;
  int? validated;
  String? createdAt;
  bool? possibleSpam;
  bool? verifiedContract;
  Links? links;
  int? securityScore;

  Erc20TokenInfoMoralis({
    this.address,
    this.addressLabel,
    this.name,
    this.symbol,
    this.decimals,
    this.logo,
    this.logoHash,
    this.thumbnail,
    this.totalSupply,
    this.totalSupplyFormatted,
    this.fullyDilutedValuation,
    this.blockNumber,
    this.validated,
    this.createdAt,
    this.possibleSpam,
    this.verifiedContract,
    this.links,
    this.securityScore,
  });

  Erc20TokenInfoMoralis.fromJson(Map<String, dynamic> json) {
    address = json['address'] as String?;
    addressLabel = json['address_label'] as String?;
    name = json['name'] as String?;
    symbol = json['symbol'] as String?;
    decimals = json['decimals'] as String?;
    logo = json['logo'] as String?;
    logoHash = json['logo_hash'] as String?;
    thumbnail = json['thumbnail'] as String?;
    totalSupply = json['total_supply'] as String?;
    totalSupplyFormatted = json['total_supply_formatted'] as String?;
    fullyDilutedValuation = json['fully_diluted_valuation'] as String?;
    blockNumber = json['block_number'] as String?;
    validated = json['validated'] as int?;
    createdAt = json['created_at'] as String?;
    possibleSpam = json['possible_spam'] as bool?;
    verifiedContract = json['verified_contract'] as bool;
    links =
        json['links'] != null ? new Links.fromJson(json['links'] as Map<String, dynamic>) : null;
    securityScore = json['security_score'] as int?;
  }
}

class Links {
  String? twitter;
  String? website;
  String? facebook;
  String? reddit;
  String? github;
  String? linkedin;
  String? telegram;

  Links({this.twitter, this.website, this.facebook, this.reddit});

  Links.fromJson(Map<String, dynamic> json) {
    twitter = json['twitter'] as String?;
    website = json['website'] as String?;
    facebook = json['facebook'] as String?;
    reddit = json['reddit'] as String?;
    github = json['github'] as String?;
    linkedin = json['linkedin'] as String?;
    telegram = json['telegram'] as String?;
  }
}
