import 'package:cw_core/utils/socket_health_logger.dart';
import 'package:mobx/mobx.dart';

part 'socket_health_logs_view_model.g.dart';

class SocketHealthLogsViewModel = SocketHealthLogsViewModelBase with _$SocketHealthLogsViewModel;

abstract class SocketHealthLogsViewModelBase with Store {
  final SocketHealthLogger _logger = SocketHealthLogger();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  List<SocketHealthLogEntry> logs = [];

  @computed
  int get totalLogs => logs.length;

  @computed
  int get unhealthyLogs => logs.where((log) => !log.isHealthy).length;

  @computed
  int get healthyLogs => totalLogs - unhealthyLogs;

  @action
  Future<void> loadLogs() async {
    isLoading = true;
    error = null;

    try {
      logs = await _logger.getLogs();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> clearLogs() async {
    await _logger.clearLogs();
    await loadLogs();
  }

  String getLogsAsText() {
    if (logs.isEmpty) return 'No logs available';

    final buffer = StringBuffer();
    buffer.writeln('Socket Health Logs');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: $totalLogs');
    buffer.writeln('Unhealthy logs: $unhealthyLogs');
    buffer.writeln('Healthy logs: $healthyLogs');
    buffer.writeln('');

    for (final log in logs) {
      buffer.writeln(log.toLogString());
    }

    return buffer.toString();
  }
}
