import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:mobx/mobx.dart';

part 'exchange_provider_logs_view_model.g.dart';

enum LogFilter { all, success, error }

class ExchangeProviderLogsViewModel = ExchangeProviderLogsViewModelBase with _$ExchangeProviderLogsViewModel;

abstract class ExchangeProviderLogsViewModelBase with Store {
  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<ExchangeProviderLogEntry> logs = ObservableList<ExchangeProviderLogEntry>();

  @observable
  LogFilter currentFilter = LogFilter.all;

  @computed
  ObservableList<ExchangeProviderLogEntry> get filteredLogs {
    switch (currentFilter) {
      case LogFilter.all:
        return logs;
      case LogFilter.success:
        return ObservableList.of(logs.where((log) => log.isSuccess).toList());
      case LogFilter.error:
        return ObservableList.of(logs.where((log) => !log.isSuccess).toList());
    }
  }

  @computed
  int get totalLogs => logs.length;

  @computed
  int get successLogs => logs.where((log) => log.isSuccess).length;

  @computed
  int get errorLogs => logs.where((log) => !log.isSuccess).length;

  @computed
  Map<ExchangeProviderDescription, int> get logsByProvider {
    final Map<ExchangeProviderDescription, int> counts = {};
    for (final log in logs) {
      counts[log.provider] = (counts[log.provider] ?? 0) + 1;
    }
    return counts;
  }

  String getLogsAsText() => ExchangeProviderLogger.getLogsAsText();

  String getLogsAsJson() => ExchangeProviderLogger.getLogsAsJson();

  @action
  void loadLogs() {
    isLoading = true;
    error = null;
    
    try {
      logs.clear();
      logs.addAll(ExchangeProviderLogger.logs);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  void clearLogs() {
    ExchangeProviderLogger.clearLogs();
    logs.clear();
  }

  @action
  void refreshLogs() => loadLogs();

  @action
  void setFilter(LogFilter filter) => currentFilter = filter;
}
