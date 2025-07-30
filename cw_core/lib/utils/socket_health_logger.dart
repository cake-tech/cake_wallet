import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:path_provider/path_provider.dart';

class SocketHealthLogEntry {
  final DateTime timestamp;
  final WalletType walletType;
  final String walletName;
  final bool isHealthy;
  final String? error;
  final String? syncStatus;
  final bool wasReconnected;
  final String trigger;

  SocketHealthLogEntry({
    required this.timestamp,
    required this.walletType,
    required this.walletName,
    required this.isHealthy,
    this.error,
    this.syncStatus,
    required this.wasReconnected,
    required this.trigger,
  });

  String toLogString() {
    final dateStr = timestamp.toIso8601String();
    final status = isHealthy ? 'HEALTHY' : 'UNHEALTHY';
    final reconnect = wasReconnected ? 'RECONNECTED' : 'NO_RECONNECT';
    final errorStr = error != null ? ' | Error: $error' : '';
    final syncStr = syncStatus != null ? ' | Sync: $syncStatus' : '';

    return '[$dateStr] $trigger | ${walletType.name} | $walletName | $status | $reconnect$errorStr$syncStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'walletType': walletType.name,
      'walletName': walletName,
      'isHealthy': isHealthy,
      'error': error,
      'syncStatus': syncStatus,
      'wasReconnected': wasReconnected,
      'trigger': trigger,
    };
  }

  factory SocketHealthLogEntry.fromJson(Map<String, dynamic> json) {
    return SocketHealthLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      walletType: WalletType.values.firstWhere((e) => e.name == json['walletType'] as String),
      walletName: json['walletName'] as String,
      isHealthy: json['isHealthy'] as bool,
      error: json['error'] as String?,
      syncStatus: json['syncStatus'] as String?,
      wasReconnected: json['wasReconnected'] as bool,
      trigger: json['trigger'] as String,
    );
  }
}

class SocketHealthLogger {
  static final SocketHealthLogger _instance = SocketHealthLogger._internal();
  factory SocketHealthLogger() => _instance;
  SocketHealthLogger._internal();

  static const String _logFileName = 'socket_health_logs.json';
  static const int _maxLogs = 1000;

  Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_logFileName');
  }

  Future<List<SocketHealthLogEntry>> getLogs() async {
    try {
      final file = await _logFile;

      if (!await file.exists()) return [];

      final content = await file.readAsString();

      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

      return jsonList
          .map((json) => SocketHealthLogEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      printV('Failed to load logs: $e');
      return [];
    }
  }

  Future<void> addLog(SocketHealthLogEntry entry) async {
    try {
      printV('Adding log entry: ${entry.toLogString()}');
      final logs = await getLogs();
      logs.add(entry);

      if (logs.length > _maxLogs) {
        logs.removeRange(0, logs.length - _maxLogs);
      }

      final file = await _logFile;

      final jsonList = logs.map((log) => log.toJson()).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      printV('Failed to save log: $e');
    }
  }

  Future<void> clearLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.delete();
      }
      printV('Cleared all logs');
    } catch (e) {
      printV('Failed to clear logs: $e');
    }
  }

  Future<void> logHealthCheck({
    required WalletType walletType,
    required String walletName,
    required bool isHealthy,
    String? error,
    String? syncStatus,
    required bool wasReconnected,
    required String trigger,
  }) async {
    final entry = SocketHealthLogEntry(
      timestamp: DateTime.now(),
      walletType: walletType,
      walletName: walletName,
      isHealthy: isHealthy,
      error: error,
      syncStatus: syncStatus,
      wasReconnected: wasReconnected,
      trigger: trigger,
    );

    await addLog(entry);
  }
}
