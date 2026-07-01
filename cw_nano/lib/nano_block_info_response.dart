class BlockContentsResponse {
  String type;
  String account;
  String previous;
  String representative;
  String balance;
  String link;
  String linkAsAccount;
  String signature;
  String work;

  BlockContentsResponse({
    required this.type,
    required this.account,
    required this.previous,
    required this.representative,
    required this.balance,
    required this.link,
    required this.linkAsAccount,
    required this.signature,
    required this.work,
  });

  factory BlockContentsResponse.fromJson(Map<String, dynamic> json) {
    return BlockContentsResponse(
      type: json['type'] as String,
      account: json['account'] as String,
      previous: json['previous'] as String,
      representative: json['representative'] as String,
      balance: json['balance'] as String,
      link: json['link'] as String,
      linkAsAccount: json['link_as_account'] as String,
      signature: json['signature'] as String,
      work: json['work'] as String,
    );
  }
}
