import 'dart:convert';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

class ExchangeProviderLogEntry {
  final DateTime timestamp;
  final ExchangeProviderDescription provider;
  final String function;
  final String? error;
  final String? stackTrace;
  final String? callStack;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  final bool isSuccess;

  ExchangeProviderLogEntry({
    required this.timestamp,
    required this.provider,
    required this.function,
    this.error,
    this.stackTrace,
    this.callStack,
    this.requestData,
    this.responseData,
    required this.isSuccess,
  });

  String toLogString() {
    final buffer = StringBuffer();
    buffer.writeln('Provider: ${provider.title}');
    buffer.writeln('Function: $function');
    buffer.writeln('Timestamp: ${timestamp.toIso8601String()}');
    buffer.writeln('Success: $isSuccess');

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    if (stackTrace != null) {
      buffer.writeln('StackTrace: $stackTrace');
    }

    if (callStack != null) {
      buffer.writeln('CallStack: $callStack');
    }

    if (requestData != null) {
      buffer.writeln('Request: ${json.encode(requestData)}');
    }

    if (responseData != null) {
      buffer.writeln('Response: ${json.encode(responseData)}');
    }

    buffer.writeln('---');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'provider': provider.title,
      'function': function,
      'error': error,
      'stackTrace': stackTrace,
      'callStack': callStack,
      'requestData': requestData,
      'responseData': responseData,
      'isSuccess': isSuccess,
    };
  }

  factory ExchangeProviderLogEntry.fromJson(Map<String, dynamic> json) {
    final allProviders = [
      ExchangeProviderDescription.xmrto,
      ExchangeProviderDescription.changeNow,
      ExchangeProviderDescription.morphToken,
      ExchangeProviderDescription.sideShift,
      ExchangeProviderDescription.simpleSwap,
      ExchangeProviderDescription.trocador,
      ExchangeProviderDescription.exolix,
      ExchangeProviderDescription.all,
      ExchangeProviderDescription.thorChain,
      ExchangeProviderDescription.swapTrade,
      ExchangeProviderDescription.letsExchange,
      ExchangeProviderDescription.stealthEx,
      ExchangeProviderDescription.chainflip,
      ExchangeProviderDescription.xoSwap,
    ];

    return ExchangeProviderLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: allProviders.firstWhere(
        (p) => p.title == json['provider'] as String,
        orElse: () => ExchangeProviderDescription.changeNow,
      ),
      function: json['function'] as String,
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
      callStack: json['callStack'] as String?,
      requestData: json['requestData'] as Map<String, dynamic>?,
      responseData: json['responseData'] as Map<String, dynamic>?,
      isSuccess: json['isSuccess'] as bool,
    );
  }
}

class ExchangeProviderLogger {
  static final List<ExchangeProviderLogEntry> _logs = [];
  static const int maxLogs = 100;

  static List<ExchangeProviderLogEntry> get logs => List.unmodifiable(_logs);

  static void logSuccess({
    required ExchangeProviderDescription provider,
    required String function,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    String? callStack,
  }) {
    final entry = ExchangeProviderLogEntry(
      timestamp: DateTime.now(),
      provider: provider,
      function: function,
      requestData: requestData,
      responseData: responseData,
      callStack: callStack,
      isSuccess: true,
    );

    _addLog(entry);
  }

  static void logError({
    required ExchangeProviderDescription provider,
    required String function,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? requestData,
    String? callStack,
  }) {
    final entry = ExchangeProviderLogEntry(
      timestamp: DateTime.now(),
      provider: provider,
      function: function,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      requestData: requestData,
      callStack: callStack,
      isSuccess: false,
    );

    _addLog(entry);
  }

  static void _addLog(ExchangeProviderLogEntry entry) {
    _logs.insert(0, entry);

    if (_logs.length > maxLogs * 2) {
      final excessCount = _logs.length - maxLogs;
      _logs.removeRange(0, excessCount);
    }
  }

  static void clearLogs() {
    _logs.clear();
  }

  static String getLogsAsText() {
    if (_logs.isEmpty) return 'No exchange provider logs available';

    final buffer = StringBuffer();
    buffer.writeln('Exchange Provider Logs');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: ${_logs.length}');
    buffer.writeln('Success logs: ${_logs.where((log) => log.isSuccess).length}');
    buffer.writeln('Error logs: ${_logs.where((log) => !log.isSuccess).length}');
    buffer.writeln('');

    for (final log in _logs) {
      buffer.writeln(log.toLogString());
    }

    return buffer.toString();
  }

  static String getLogsAsJson() {
    return json.encode(_logs.map((log) => log.toJson()).toList());
  }
}
