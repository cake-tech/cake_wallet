class SolanaSignMessage {
  final String pubkey;
  final String message;

  SolanaSignMessage({
    required this.pubkey,
    required this.message,
  });

  factory SolanaSignMessage.fromJson(Map<String, dynamic> json) {
    return SolanaSignMessage(
      pubkey: json['pubkey'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'SolanaSignMessage(pubkey: $pubkey, message: $message)';
  }
}
