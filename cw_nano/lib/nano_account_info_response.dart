class AccountInfoResponse {
  String frontier;
  int confirmationHeight;
  String balance;
  String representative;
  String? address;
  String? openBlock;

  AccountInfoResponse({
    required this.frontier,
    required this.openBlock,
    required this.balance,
    required this.representative,
    required this.confirmationHeight,
  });

  factory AccountInfoResponse.fromJson(Map<String, dynamic> json) {
    return AccountInfoResponse(
      frontier: json['frontier'] as String,
      representative: json['representative'] as String,
      balance: json['balance'] as String,
      confirmationHeight: int.parse(json['confirmation_height'] as String),
      openBlock: json['open_block'] as String?,
    );
  }
}
