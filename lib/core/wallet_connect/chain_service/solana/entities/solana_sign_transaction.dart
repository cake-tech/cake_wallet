class SolanaSignTransaction {
  final String feePayer;
  final String recentBlockhash;
  final List<SolanaInstruction> instructions;

  SolanaSignTransaction({
    required this.feePayer,
    required this.recentBlockhash,
    required this.instructions,
  });

  factory SolanaSignTransaction.fromJson(Map<String, dynamic> json) {
    return SolanaSignTransaction(
      feePayer: json['feePayer'] as String,
      recentBlockhash: json['recentBlockhash'] as String,
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => SolanaInstruction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feePayer': feePayer,
      'recentBlockhash': recentBlockhash,
      'instructions': instructions,
    };
  }

  @override
  String toString() {
    return 'SolanaSignTransaction(feePayer: $feePayer, recentBlockhash: $recentBlockhash, instructions: $instructions)';
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
