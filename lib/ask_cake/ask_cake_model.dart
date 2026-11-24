import 'dart:convert';

import 'package:flutter/services.dart';

class AskCakeAvailability {
  const AskCakeAvailability({required this.available, this.modelName, this.reason, this.contextSize});

  final bool available;
  final String? modelName;
  final String? reason;
  final int? contextSize;

  String get reasonText => switch (reason) {
        'deviceNotEligible' => 'This device does not support Apple Intelligence.',
        'appleIntelligenceNotEnabled' => 'Turn on Apple Intelligence in Settings to use Ask Cake.',
        'modelNotReady' => 'The on-device model is still downloading. Try again shortly.',
        'osTooOld' => 'Ask Cake needs iOS 26 or later.',
        'unsupportedPlatform' => 'Ask Cake currently needs an Apple Intelligence capable iPhone.',
        _ => 'The on-device model is unavailable.',
      };
}

class AskCakeModelException implements Exception {
  AskCakeModelException(this.code, [this.message]);

  /// guardrail, context, unavailable, noSession or generation
  final String code;
  final String? message;

  @override
  String toString() => 'AskCakeModelException($code, $message)';
}

/// One property of a flat JSON object the model must produce.
class AskCakeField {
  const AskCakeField.string(this.name, {this.description, this.optional = true})
      : type = 'string',
        values = null;

  const AskCakeField.integer(this.name, {this.description, this.optional = true})
      : type = 'int',
        values = null;

  const AskCakeField.boolean(this.name, {this.description, this.optional = true})
      : type = 'bool',
        values = null;

  const AskCakeField.choice(this.name, List<String> this.values,
      {this.description, this.optional = false})
      : type = 'enum';

  final String name;
  final String type;
  final String? description;
  final List<String>? values;
  final bool optional;

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        if (description != null) 'description': description,
        if (values != null) 'values': values,
        'optional': optional,
      };
}

/// The only two things Ask Cake needs from a language model: free text, and
/// text constrained to a small flat schema. Everything else (routing, wallet
/// tools, validation) is plain Dart, so any on-device model that can do
/// constrained decoding can sit behind this interface.
abstract class AskCakeLanguageModel {
  Future<AskCakeAvailability> availability();

  /// [permissive] is for sessions that only rephrase text the app supplies
  /// (wallet data, docs excerpts); backends without guardrails ignore it.
  Future<String> createSession(String instructions, {bool permissive = false});

  Future<void> disposeSession(String sessionId);

  Future<String> respond(String sessionId, String prompt);

  Future<Map<String, dynamic>> respondStructured(
      String sessionId, String prompt, String schemaName, List<AskCakeField> fields);
}

/// Apple's on-device Foundation Models, via ios/Runner/AskCakeModel.swift.
class AppleFoundationLanguageModel implements AskCakeLanguageModel {
  static const _channel = MethodChannel('com.cake_wallet/ask_cake');

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw AskCakeModelException(e.code, e.message);
    } on MissingPluginException {
      throw AskCakeModelException('unavailable', 'unsupportedPlatform');
    }
  }

  @override
  Future<AskCakeAvailability> availability() async {
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('availability') ?? {};
      return AskCakeAvailability(
        available: info['available'] == true,
        modelName: info['model'] as String?,
        reason: info['reason'] as String?,
        contextSize: info['contextSize'] as int?,
      );
    } on MissingPluginException {
      return const AskCakeAvailability(available: false, reason: 'unsupportedPlatform');
    }
  }

  @override
  Future<String> createSession(String instructions, {bool permissive = false}) async =>
      (await _invoke<String>('createSession', {'instructions': instructions, 'permissive': permissive}))!;

  @override
  Future<void> disposeSession(String sessionId) =>
      _invoke<void>('disposeSession', {'sessionId': sessionId});

  @override
  Future<String> respond(String sessionId, String prompt) async =>
      (await _invoke<String>('respond', {'sessionId': sessionId, 'prompt': prompt})) ?? '';

  @override
  Future<Map<String, dynamic>> respondStructured(
      String sessionId, String prompt, String schemaName, List<AskCakeField> fields) async {
    final raw = await _invoke<String>('respond', {
      'sessionId': sessionId,
      'prompt': prompt,
      'schema': {'name': schemaName, 'properties': fields.map((f) => f.toMap()).toList()},
    });
    final decoded = jsonDecode(raw ?? '{}');
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
