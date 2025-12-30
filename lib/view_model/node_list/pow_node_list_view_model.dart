import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/entities/node_list.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cw_core/wallet_type.dart';

part 'pow_node_list_view_model.g.dart';

class PowNodeListViewModel = PowNodeListViewModelBase with _$PowNodeListViewModel;

abstract class PowNodeListViewModelBase with Store {
  PowNodeListViewModelBase(this._appStore)
      : nodes = ObservableList<Node>(),
        settingsStore = _appStore.settingsStore {
    bindNodes();

    reaction((_) => _appStore.wallet, (WalletBase? _wallet) {
      bindNodes();
    });
  }

  @computed
  Node get currentNode {
    final node = settingsStore.powNodes[_appStore.wallet!.type];

    if (node == null) {
      throw Exception('No node for wallet type: ${_appStore.wallet!.type}');
    }

    return node;
  }

  String getAlertContent(String uri) =>
      S.current.change_current_node(uri) +
      '${uri.endsWith('.onion') || uri.contains('.onion:') ? '\n' + (CakeTor.instance!.enabled ? '' : S.current.orbot_running_alert) : ''}';

  @computed
  bool get enableAutomaticNodeSwitching => settingsStore.enableAutomaticNodeSwitching;

  @action
  void setEnableAutomaticNodeSwitching(bool value) =>
      settingsStore.enableAutomaticNodeSwitching = value;

  final ObservableList<Node> nodes;
  final SettingsStore settingsStore;
  final AppStore _appStore;

  Future<void> reset() async {
    await resetPowToDefault();

    Node node;

    switch (_appStore.wallet!.type) {
      case WalletType.nano:
        node = (await getNanoDefaultPowNode())!;
        break;
      default:
        throw Exception('Unexpected wallet type: ${_appStore.wallet!.type}');
    }

    await setAsCurrent(node);
  }

  @action
  Future<void> delete(Node node) async => node.delete();

  Future<void> setAsCurrent(Node node) async =>
      settingsStore.powNodes[_appStore.wallet!.type] = node;

  @action
  Future<void> bindNodes() async  {
    nodes.clear();
    nodes.addAll(await Node.getAllPow());
  }
}
