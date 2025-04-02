class SolanaSignTransaction {
  final String? feePayer;
  final String? recentBlockhash;
  final String transaction;
  final List<SolanaInstruction>? instructions;

  SolanaSignTransaction({
    required this.feePayer,
    required this.recentBlockhash,
    required this.instructions,
    required this.transaction,
  });

  factory SolanaSignTransaction.fromJson(Map<String, dynamic> json) {
    return SolanaSignTransaction(
      feePayer:json['feePayer'] !=null ? json['feePayer'] as String: null,
      recentBlockhash: json['recentBlockhash']!=null? json['recentBlockhash'] as String: null,
      instructions:json['instructions']!=null? (json['instructions'] as List<dynamic>)
          .map((e) => SolanaInstruction.fromJson(e as Map<String, dynamic>))
          .toList(): null,
      transaction: json['transaction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feePayer': feePayer,
      'recentBlockhash': recentBlockhash,
      'instructions': instructions,
      'transaction': transaction,
    };
  }

  @override
  String toString() {
    return 'SolanaSignTransaction(feePayer: $feePayer, recentBlockhash: $recentBlockhash, instructions: $instructions, transaction: $transaction)';
  }
}

class SolanaInstruction {
  final String programId;
  final List<SolanaKeyMetadata> keys;
  final List<int> data;

  SolanaInstruction({
    required this.programId,
    required this.keys,
    required this.data,
  });

  factory SolanaInstruction.fromJson(Map<String, dynamic> json) {
    return SolanaInstruction(
      programId: json['programId'] as String,
      keys: (json['keys'] as List<dynamic>)
          .map((e) => SolanaKeyMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
      data: (json['data'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'programId': programId,
      'keys': keys,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'SolanaInstruction(programId: $programId, keys: $keys, data: $data)';
  }
}

class SolanaKeyMetadata {
  final String pubkey;
  final bool isSigner;
  final bool isWritable;

  SolanaKeyMetadata({
    required this.pubkey,
    required this.isSigner,
    required this.isWritable,
  });

  factory SolanaKeyMetadata.fromJson(Map<String, dynamic> json) {
    return SolanaKeyMetadata(
      pubkey: json['pubkey'] as String,
      isSigner: json['isSigner'] as bool,
      isWritable: json['isWritable'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'isSigner': isSigner,
      'isWritable': isWritable,
    };
  }

  @override
  String toString() {
    return 'SolanaKeyMetadata(pubkey: $pubkey, isSigner: $isSigner, isWritable: $isWritable)';
  }
}
