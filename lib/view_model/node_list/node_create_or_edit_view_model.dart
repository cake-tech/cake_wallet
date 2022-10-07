import 'package:cake_wallet/core/execution_state.dart';
import 'package:cw_haven/haven_wallet.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase
    with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(this._nodeSource, this._wallet)
      : state = InitialExecutionState(),
        connectionState = InitialExecutionState(),
        useSSL = false,
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
  bool get isReady =>
      (address?.isNotEmpty ?? false) && (port?.isNotEmpty ?? false);

  bool get hasAuthCredentials => _wallet.type == WalletType.monero ||
    _wallet.type == WalletType.haven;

  String get uri {
    var uri = address;

    if (port != null && port.isNotEmpty) {
      uri += ':' + port;
    }

    return uri;
  }

  final WalletBase _wallet;
  final Box<Node> _nodeSource;

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
  Future<void> save() async {
    try {
      state = IsExecutingState();
      final node =
          Node(uri: uri, type: _wallet.type, login: login, password: password,
              useSSL: useSSL, trusted: trusted);
      if (_wallet.type == WalletType.monero) {
        (_wallet as MoneroWallet).setTrustedDaemon(trusted);
      } else if (_wallet.type == WalletType.haven) {
        (_wallet as HavenWallet).setTrustedDaemon(trusted);
      }
      await _nodeSource.add(node);
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> connect() async {
    try {
      connectionState = IsExecutingState();
      final node =
        Node(uri: uri, type: _wallet.type, login: login, password: password);
      final isAlive = await node.requestNode();
      connectionState = ExecutedSuccessfullyState(payload: isAlive);
    } catch (e) {
      connectionState = FailureState(e.toString());
    }
  }
}
