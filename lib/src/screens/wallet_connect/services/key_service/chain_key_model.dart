import 'dart:convert';

class ChainKeyModel {
  final List<String> chains;
  final String privateKey;
  final String publicKey;

  ChainKeyModel({
    required this.chains,
    required this.privateKey,
    required this.publicKey,
  });

  String get namespace {
    if (chains.isNotEmpty) {
      return chains.first.split(':').first;
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'chains': chains,
        'privateKey': privateKey,
        'publicKey': privateKey,
      };

  factory ChainKeyModel.fromJson(Map<String, dynamic> json) {
    return ChainKeyModel(
      chains: (json['chains'] as List).map((e) => '$e').toList(),
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
