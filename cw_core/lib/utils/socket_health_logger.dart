import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';

class SocketHealthLogEntry {
  final DateTime timestamp;
  final WalletType? walletType;
  final String? walletName;
  final bool? isHealthy;
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
    final status = isHealthy != null ? (isHealthy! ? 'HEALTHY' : 'UNHEALTHY') : 'UNKNOWN';
    final reconnect = wasReconnected ? 'RECONNECTED' : 'NO_RECONNECT';
    final errorStr = error != null ? ' | Error: $error' : '';
    final syncStr = syncStatus != null ? ' | Sync: $syncStatus' : '';

    return '[$dateStr] $trigger | ${walletType?.name ?? 'UNKNOWN'} | $walletName | $status | $reconnect$errorStr$syncStr';
  }
}

class SocketHealthLogger {
  static final SocketHealthLogger _instance = SocketHealthLogger._internal();
  factory SocketHealthLogger() => _instance;
  SocketHealthLogger._internal();

  static const int _maxLogs = 100;

  static final List<SocketHealthLogEntry> logs = [];

  void addLog(SocketHealthLogEntry entry) {
    try {
      printV('Adding log entry: ${entry.toLogString()}');

      logs.add(entry);

      if (logs.length > _maxLogs * 2) {
        final excessCount = logs.length - _maxLogs;
        logs.removeRange(0, excessCount);
      }
    } catch (e) {
      printV('Failed to add log: $e');
    }
  }

  void clearLogs() {
    logs.clear();
    printV('Cleared all logs');
  }

  /// Log a health check with the given parameters
  void logHealthCheck({
    WalletType? walletType,
    String? walletName,
    bool? isHealthy,
    String? error,
    String? syncStatus,
    required bool wasReconnected,
    required String trigger,
  }) {
    addLog(
      SocketHealthLogEntry(
        timestamp: DateTime.now(),
        walletType: walletType,
        walletName: walletName,
        isHealthy: isHealthy,
        error: error,
        syncStatus: syncStatus,
        wasReconnected: wasReconnected,
        trigger: trigger,
      ),
    );
  }
}
