import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:mobx/mobx.dart';

part 'background_sync_logs_view_model.g.dart';
class BackgroundSyncLogsViewModel = BackgroundSyncLogsViewModelBase with _$BackgroundSyncLogsViewModel;

abstract class BackgroundSyncLogsViewModelBase with Store {
  final FlutterDaemon _daemon = FlutterDaemon();

  @observable
  LogData? logData;

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @computed
  List<LogEntry> get logs => logData?.logs ?? [];

  @computed
  List<LogSession> get sessions => logData?.sessions ?? [];

  @action
  Future<void> loadLogs() async {
    isLoading = true;
    error = null;
    
    try {
      logData = await _daemon.getLogs();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> clearLogs() async {
    await _daemon.clearLogs();
    await loadLogs();
  }
} 