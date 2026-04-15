import 'dart:convert';

import 'package:ur/cbor_lite.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_decoder.dart';
import 'package:ur/ur_encoder.dart';

const String starknetSignRequestUrType = 'starknet-sign-request';
const String starknetSignResponseUrType = 'starknet-sign-response';
const String starknetMessageSignRequestUrType = 'starknet-message-sign-request';
const String starknetMessageSignResponseUrType = 'starknet-message-sign-response';
const String starknetTypedDataSignRequestUrType = 'starknet-typed-data-sign-request';
const String starknetTypedDataSignResponseUrType = 'starknet-typed-data-sign-response';
const int _defaultUrFragmentLength = 120;

class StarknetUrSignature {
  StarknetUrSignature({
    required this.rHex,
    required this.sHex,
  });

  factory StarknetUrSignature.fromJson(Map<String, dynamic> json) => StarknetUrSignature(
        rHex: json['rHex'] as String,
        sHex: json['sHex'] as String,
      );

  final String rHex;
  final String sHex;

  Map<String, dynamic> toJson() => {
        'rHex': rHex,
        'sHex': sHex,
      };
}

class StarknetSignRequestUrPayload {
  StarknetSignRequestUrPayload({
    required this.planJson,
    required this.accountAddressHex,
    required this.publicKeyHex,
    required this.accountClassHashHex,
    required this.invokeTransactionHashHex,
    required this.amountWei,
    required this.amountDecimals,
    required this.amountSymbol,
    required this.destinationAddress,
    required this.feeWei,
    this.summaryActionName,
    this.summaryTokenAddress,
    this.summaryAdditionalInfo,
    this.preferSummary = false,
    this.deployAccountTransactionHashHex,
    this.version = 1,
  });

  factory StarknetSignRequestUrPayload.fromJson(Map<String, dynamic> json) =>
      StarknetSignRequestUrPayload(
        version: json['version'] as int? ?? 1,
        planJson: json['planJson'] as String,
        accountAddressHex: json['accountAddressHex'] as String,
        publicKeyHex: json['publicKeyHex'] as String,
        accountClassHashHex: json['accountClassHashHex'] as String,
        invokeTransactionHashHex: json['invokeTransactionHashHex'] as String,
        deployAccountTransactionHashHex: json['deployAccountTransactionHashHex'] as String?,
        amountWei: json['amountWei'] as String,
        amountDecimals: json['amountDecimals'] as int,
        amountSymbol: json['amountSymbol'] as String,
        destinationAddress: json['destinationAddress'] as String,
        feeWei: json['feeWei'] as String,
        summaryActionName: json['summaryActionName'] as String?,
        summaryTokenAddress: json['summaryTokenAddress'] as String?,
        summaryAdditionalInfo: json['summaryAdditionalInfo'] == null
            ? null
            : Map<String, dynamic>.from(json['summaryAdditionalInfo'] as Map),
        preferSummary: json['preferSummary'] as bool? ?? false,
      );

  final int version;
  final String planJson;
  final String accountAddressHex;
  final String publicKeyHex;
  final String accountClassHashHex;
  final String invokeTransactionHashHex;
  final String? deployAccountTransactionHashHex;
  final String amountWei;
  final int amountDecimals;
  final String amountSymbol;
  final String destinationAddress;
  final String feeWei;
  final String? summaryActionName;
  final String? summaryTokenAddress;
  final Map<String, dynamic>? summaryAdditionalInfo;
  final bool preferSummary;

  Map<String, dynamic> toJson() => {
        'version': version,
        'planJson': planJson,
        'accountAddressHex': accountAddressHex,
        'publicKeyHex': publicKeyHex,
        'accountClassHashHex': accountClassHashHex,
        'invokeTransactionHashHex': invokeTransactionHashHex,
        'deployAccountTransactionHashHex': deployAccountTransactionHashHex,
        'amountWei': amountWei,
        'amountDecimals': amountDecimals,
        'amountSymbol': amountSymbol,
        'destinationAddress': destinationAddress,
        'feeWei': feeWei,
        'summaryActionName': summaryActionName,
        'summaryTokenAddress': summaryTokenAddress,
        'summaryAdditionalInfo': summaryAdditionalInfo,
        'preferSummary': preferSummary,
      };
}

class StarknetSignResponseUrPayload {
  StarknetSignResponseUrPayload({
    required this.planJson,
    required this.invokeTransactionHashHex,
    required this.invokeSignature,
    this.deployAccountTransactionHashHex,
    this.deploySignature,
    this.version = 1,
  });

  factory StarknetSignResponseUrPayload.fromJson(Map<String, dynamic> json) =>
      StarknetSignResponseUrPayload(
        version: json['version'] as int? ?? 1,
        planJson: json['planJson'] as String,
        invokeTransactionHashHex: json['invokeTransactionHashHex'] as String,
        invokeSignature:
            StarknetUrSignature.fromJson(Map<String, dynamic>.from(json['invokeSignature'] as Map)),
        deployAccountTransactionHashHex: json['deployAccountTransactionHashHex'] as String?,
        deploySignature: json['deploySignature'] == null
            ? null
            : StarknetUrSignature.fromJson(
                Map<String, dynamic>.from(json['deploySignature'] as Map),
              ),
      );

  final int version;
  final String planJson;
  final String invokeTransactionHashHex;
  final StarknetUrSignature invokeSignature;
  final String? deployAccountTransactionHashHex;
  final StarknetUrSignature? deploySignature;

  Map<String, dynamic> toJson() => {
        'version': version,
        'planJson': planJson,
        'invokeTransactionHashHex': invokeTransactionHashHex,
        'invokeSignature': invokeSignature.toJson(),
        'deployAccountTransactionHashHex': deployAccountTransactionHashHex,
        'deploySignature': deploySignature?.toJson(),
      };
}

class StarknetMessageSignRequestUrPayload {
  StarknetMessageSignRequestUrPayload({
    required this.accountAddressHex,
    required this.publicKeyHex,
    required this.message,
    required this.messageHashHex,
    this.version = 1,
  });

  factory StarknetMessageSignRequestUrPayload.fromJson(Map<String, dynamic> json) =>
      StarknetMessageSignRequestUrPayload(
        version: json['version'] as int? ?? 1,
        accountAddressHex: json['accountAddressHex'] as String,
        publicKeyHex: json['publicKeyHex'] as String,
        message: json['message'] as String,
        messageHashHex: json['messageHashHex'] as String,
      );

  final int version;
  final String accountAddressHex;
  final String publicKeyHex;
  final String message;
  final String messageHashHex;

  Map<String, dynamic> toJson() => {
        'version': version,
        'accountAddressHex': accountAddressHex,
        'publicKeyHex': publicKeyHex,
        'message': message,
        'messageHashHex': messageHashHex,
      };
}

class StarknetTypedDataSignRequestUrPayload {
  StarknetTypedDataSignRequestUrPayload({
    required this.accountAddressHex,
    required this.publicKeyHex,
    required this.typedDataJson,
    required this.typedDataHashHex,
    this.version = 1,
  });

  factory StarknetTypedDataSignRequestUrPayload.fromJson(Map<String, dynamic> json) =>
      StarknetTypedDataSignRequestUrPayload(
        version: json['version'] as int? ?? 1,
        accountAddressHex: json['accountAddressHex'] as String,
        publicKeyHex: json['publicKeyHex'] as String,
        typedDataJson: json['typedDataJson'] as String,
        typedDataHashHex: json['typedDataHashHex'] as String,
      );

  final int version;
  final String accountAddressHex;
  final String publicKeyHex;
  final String typedDataJson;
  final String typedDataHashHex;

  Map<String, dynamic> toJson() => {
        'version': version,
        'accountAddressHex': accountAddressHex,
        'publicKeyHex': publicKeyHex,
        'typedDataJson': typedDataJson,
        'typedDataHashHex': typedDataHashHex,
      };
}

class StarknetSignatureResponseUrPayload {
  StarknetSignatureResponseUrPayload({
    required this.messageHashHex,
    required this.signature,
    this.version = 1,
  });

  factory StarknetSignatureResponseUrPayload.fromJson(Map<String, dynamic> json) =>
      StarknetSignatureResponseUrPayload(
        version: json['version'] as int? ?? 1,
        messageHashHex: json['messageHashHex'] as String,
        signature: StarknetUrSignature.fromJson(
          Map<String, dynamic>.from(json['signature'] as Map),
        ),
      );

  final int version;
  final String messageHashHex;
  final StarknetUrSignature signature;

  Map<String, dynamic> toJson() => {
        'version': version,
        'messageHashHex': messageHashHex,
        'signature': signature.toJson(),
      };
}

Map<String, String> encodeStarknetSignRequestUrMap(StarknetSignRequestUrPayload payload) => {
      'Cupcake ur': _encodeJsonUr(starknetSignRequestUrType, payload.toJson()),
    };

String encodeStarknetSignResponseUr(StarknetSignResponseUrPayload payload) =>
    _encodeJsonUr(starknetSignResponseUrType, payload.toJson());

Map<String, String> encodeStarknetMessageSignRequestUrMap(
        StarknetMessageSignRequestUrPayload payload) =>
    {
      'Cupcake ur': _encodeJsonUr(starknetMessageSignRequestUrType, payload.toJson()),
    };

String encodeStarknetMessageSignResponseUr(StarknetSignatureResponseUrPayload payload) =>
    _encodeJsonUr(starknetMessageSignResponseUrType, payload.toJson());

Map<String, String> encodeStarknetTypedDataSignRequestUrMap(
        StarknetTypedDataSignRequestUrPayload payload) =>
    {
      'Cupcake ur': _encodeJsonUr(starknetTypedDataSignRequestUrType, payload.toJson()),
    };

String encodeStarknetTypedDataSignResponseUr(StarknetSignatureResponseUrPayload payload) =>
    _encodeJsonUr(starknetTypedDataSignResponseUrType, payload.toJson());

StarknetSignRequestUrPayload decodeStarknetSignRequestUr(String input) =>
    StarknetSignRequestUrPayload.fromJson(_decodeJsonUr(input, starknetSignRequestUrType));

StarknetSignResponseUrPayload decodeStarknetSignResponseUr(String input) =>
    StarknetSignResponseUrPayload.fromJson(_decodeJsonUr(input, starknetSignResponseUrType));

StarknetMessageSignRequestUrPayload decodeStarknetMessageSignRequestUr(String input) =>
    StarknetMessageSignRequestUrPayload.fromJson(
      _decodeJsonUr(input, starknetMessageSignRequestUrType),
    );

StarknetSignatureResponseUrPayload decodeStarknetMessageSignResponseUr(String input) =>
    StarknetSignatureResponseUrPayload.fromJson(
      _decodeJsonUr(input, starknetMessageSignResponseUrType),
    );

StarknetTypedDataSignRequestUrPayload decodeStarknetTypedDataSignRequestUr(String input) =>
    StarknetTypedDataSignRequestUrPayload.fromJson(
      _decodeJsonUr(input, starknetTypedDataSignRequestUrType),
    );

StarknetSignatureResponseUrPayload decodeStarknetTypedDataSignResponseUr(String input) =>
    StarknetSignatureResponseUrPayload.fromJson(
      _decodeJsonUr(input, starknetTypedDataSignResponseUrType),
    );

String _encodeJsonUr(String type, Map<String, dynamic> jsonMap) {
  final sourceBytes = utf8.encode(json.encode(jsonMap));
  final cborEncoder = CBOREncoder();
  cborEncoder.encodeBytes(sourceBytes);

  final ur = UR(type, cborEncoder.getBytes());
  final encoder = UREncoder(ur, _defaultUrFragmentLength);
  final parts = <String>[];

  while (!encoder.isComplete) {
    parts.add(encoder.nextPart());
  }

  return parts.join('\n');
}

Map<String, dynamic> _decodeJsonUr(String input, String expectedType) {
  final decoder = URDecoder();

  for (final rawPart in input.split('\n')) {
    final part = rawPart.trim();
    if (part.isEmpty) {
      continue;
    }

    if (!part.startsWith('ur:')) {
      throw Exception('Unexpected Starknet UR fragment: $part');
    }

    decoder.receivePart(part);
  }

  if (!decoder.isComplete()) {
    throw Exception('Incomplete Starknet UR payload');
  }

  final result = decoder.result;
  if (result is! UR) {
    throw Exception('Unexpected Starknet UR decode result: ${result.runtimeType}');
  }

  if (result.type != expectedType) {
    throw Exception('Unexpected Starknet UR type: ${result.type}');
  }

  final cborDecoder = CBORDecoder(result.cbor);
  final bytes = cborDecoder.decodeBytes().$1;
  return Map<String, dynamic>.from(json.decode(utf8.decode(bytes)) as Map);
}
