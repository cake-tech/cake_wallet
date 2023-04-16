import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:collection/collection.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(this._nodeSource, this._walletType, this._settingsStore)
      : state = InitialExecutionState(),
        connectionState = InitialExecutionState(),
        useSSL = false,
        address = '',
        port = '',
        login = '',
        password = '',
        trusted = false;

  @observable
  ExecutionState state;

  @observable
  String address;

  @observable
  String port;

  @observable
  String login;

  @observable
  String password;

  @observable
  ExecutionState connectionState;

  @observable
  bool useSSL;

  @observable
  bool trusted;

  @computed
  bool get isReady => address.isNotEmpty && port.isNotEmpty;

  bool get hasAuthCredentials =>
      _walletType == WalletType.monero || _walletType == WalletType.haven;

  String get uri {
    var uri = address;

    if (port.isNotEmpty) {
      uri += ':' + port;
    }

    return uri;
  }

  final WalletType _walletType;
  final Box<Node> _nodeSource;
  final SettingsStore _settingsStore;

  @action
  void reset() {
    address = '';
    port = '';
    login = '';
    password = '';
    useSSL = false;
    trusted = false;
  }

  @action
  void setPort(String val) => port = val;

  @action
  void setAddress(String val) => address = val;

  @action
  void setLogin(String val) => login = val;

  @action
  void setPassword(String val) => password = val;

  @action
  void setSSL(bool val) => useSSL = val;

  @action
  void setTrusted(bool val) => trusted = val;

  @action
  Future<void> save({Node? editingNode, bool saveAsCurrent = false}) async {
    final node = Node(
        uri: uri,
        type: _walletType,
        login: login,
        password: password,
        useSSL: useSSL,
        trusted: trusted);
    try {
      state = IsExecutingState();
      if (editingNode != null) {
        await _nodeSource.put(editingNode.key, node);
      } else if (existingNode(node) != null) {
        setAsCurrent(existingNode(node)!);
      } else {
        await _nodeSource.add(node);
        setAsCurrent(_nodeSource.values.last);
      }
      if (saveAsCurrent) {
        setAsCurrent(node);
      }

      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> connect() async {
    final node = Node(
        uri: uri,
        type: _walletType,
        login: login,
        password: password,
        useSSL: useSSL,
        trusted: trusted);
    try {
      connectionState = IsExecutingState();
      final isAlive = await node.requestNode();
      connectionState = ExecutedSuccessfullyState(payload: isAlive);
    } catch (e) {
      connectionState = FailureState(e.toString());
    }
  }

  Node? existingNode(Node node) {
    final nodes = _nodeSource.values.toList();
    nodes.forEach((item) {
      item.login ??= '';
      item.password ??= '';
      item.useSSL ??= false;
    });
    return nodes.firstWhereOrNull((item) => item == node);
  }

  @action
  void setAsCurrent(Node node) => _settingsStore.nodes[_walletType] = node;
}
