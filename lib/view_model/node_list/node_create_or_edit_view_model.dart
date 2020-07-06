import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model_state.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase
    with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(this._nodeSource, this._wallet)
      : state = InitialNodeCreateOrEditViewModelState();

  @observable
  NodeCreateOrEditViewModelState state;

  @observable
  String address;

  @observable
  String port;

  @observable
  String login;

  @observable
  String password;

  @computed
  bool get isReady =>
      (address?.isNotEmpty ?? false) && (port?.isNotEmpty ?? false);

  bool get hasAuthCredentials => _wallet.type == WalletType.monero;

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
  }

  @action
  Future<void> save() async {
    try {
      state = NodeIsCreating();
      final node =
          Node(uri: uri, type: _wallet.type, login: login, password: password);
      await _nodeSource.add(node);
      state = NodeCreatedSuccessfully();
    } catch (e) {
      state = NodeCreateOrEditViewModelFailure(e.toString());
    }
  }
}
