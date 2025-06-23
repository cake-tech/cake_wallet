import 'package:cw_core/utils/proxy_logger/memory_proxy_logger.dart';
import 'package:mobx/mobx.dart';

part 'network_requests_view_model.g.dart';

class NetworkRequestsViewModel = NetworkRequestsViewModelBase with _$NetworkRequestsViewModel;

abstract class NetworkRequestsViewModelBase with Store {
  @observable
  List<MemoryProxyLoggerEntry> logs = MemoryProxyLogger.logs;

  @action
  Future<void> loadLogs() async {
    logs = MemoryProxyLogger.logs;
  }
} 