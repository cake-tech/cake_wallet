import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:cake_wallet/view_model/node_list/pow_node_list_view_model.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:collection/collection.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(this.isPow, this.nodeListViewModel,this.powNodeListViewModel, this._walletType, this._settingsStore)
      : state = InitialExecutionState(),
        connectionState = InitialExecutionState(),
        useSSL = false,
        address = '',
        path = '',
        port = '',
        login = '',
        password = '',
        trusted = false,
        isEnabledForAutoSwitching = false,
        useSocksProxy = false,
        socksProxyAddress = '';

  @observable
  ExecutionState state;

  @observable
  String address;

  @observable
  String path;

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

  @observable
  bool isEnabledForAutoSwitching;

  @observable
  bool useSocksProxy;

  @computed
  bool get usesEmbeddedProxy => CakeTor.instance!.started;

  @observable
  String socksProxyAddress;

  @observable
  bool isPow;

  final NodeListViewModel? nodeListViewModel;
  final PowNodeListViewModel? powNodeListViewModel;

  @computed
  bool get isReady =>
      (address.isNotEmpty) || _walletType == WalletType.decred; // Allow an empty address.

  bool get hasAuthCredentials =>
      _walletType == WalletType.monero || _walletType == WalletType.wownero || _walletType == WalletType.haven;

  bool get hasPathSupport {
    switch (_walletType) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.solana:
      case WalletType.banano:
      case WalletType.nano:
      case WalletType.tron:
        return true;
      case WalletType.none:
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.haven:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.bitcoin:
      case WalletType.dogecoin:
      case WalletType.zano:
      case WalletType.decred:
        return false;
    }
  }

  String get uri {
    var uri = address;

    if (port.isNotEmpty) {
      uri += ':' + port;
    }

    return uri;
  }

  final WalletType _walletType;
  final SettingsStore _settingsStore;

  @action
  void reset() {
    address = '';
    path = '';
    port = '';
    login = '';
    password = '';
    useSSL = false;
    trusted = false;
    isEnabledForAutoSwitching = false;
    useSocksProxy = false;
    socksProxyAddress = '';
  }

  @action
  void setPort(String val) => port = val;

  @action
  void setAddress(String val) => address = val;

  @action
  void setPath(String val) => path = val;

  @action
  void setLogin(String val) => login = val;

  @action
  void setPassword(String val) => password = val;

  @action
  void setSSL(bool val) => useSSL = val;

  @action
  void setTrusted(bool val) => trusted = val;

  @action
  void setIsEnabledForAutoSwitching(bool val) => isEnabledForAutoSwitching = val;

  @action
  void setSocksProxy(bool val) => useSocksProxy = val;

  @action
  void setSocksProxyAddress(String val) => socksProxyAddress = val;

  @action
  Future<void> delete({required Node editingNode}) async {
    await editingNode.delete();
    if(nodeListViewModel != null) {
      nodeListViewModel!.bindNodes();
    }
    if(powNodeListViewModel != null) {
      powNodeListViewModel!.bindNodes();
    }
  }

  @action
  Future<void> save({Node? editingNode, bool saveAsCurrent = false}) async {
    final node = Node(
        id: editingNode?.id ?? 0,
        uri: uri,
        path: path,
        type: _walletType,
        login: login,
        password: password,
        isPow: isPow,
        useSSL: useSSL,
        trusted: trusted,
        isEnabledForAutoSwitching: isEnabledForAutoSwitching,
        socksProxyAddress: socksProxyAddress);
    try {
      state = IsExecutingState();
      if (editingNode != null) {
        await node.save();
      } else if (await _existingNode(node) != null) {
        setAsCurrent((await _existingNode(node))!);
      } else {
        await node.save();
        setAsCurrent(node);
      }
      if (saveAsCurrent) {
        setAsCurrent(node);
      }

      state = ExecutedSuccessfullyState();
      if(nodeListViewModel != null) {
        nodeListViewModel!.bindNodes();
      }
      if(powNodeListViewModel != null) {
        powNodeListViewModel!.bindNodes();
      }

    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> connect() async {
    final node = Node(
        uri: uri,
        path: path,
        type: _walletType,
        login: login,
        password: password,
        useSSL: useSSL,
        trusted: trusted,
        isEnabledForAutoSwitching: isEnabledForAutoSwitching,
        socksProxyAddress: socksProxyAddress);
    try {
      connectionState = IsExecutingState();
      final isAlive = await node.requestNode();
      connectionState = ExecutedSuccessfullyState(payload: isAlive);
    } catch (e) {
      connectionState = FailureState(e.toString());
    }
  }

  Future<Node?> _existingNode(Node node)async {
    final nodes = isPow ? await Node.getAllPow() : await Node.getAll();
    nodes.forEach((item) {
      item.login ??= '';
      item.password ??= '';
      item.useSSL ??= false;
    });
    return nodes.firstWhereOrNull((item) => item == node);
  }

  @action
  void setAsCurrent(Node node) => _settingsStore.nodes[_walletType] = node;

  @action
  Future<void> scanQRCodeForNewNode(BuildContext context) async {
    try {
      bool isCameraPermissionGranted =
          await PermissionHandler.checkPermission(Permission.camera, context);
      if (!isCameraPermissionGranted) return;
      String? code = await presentQRScanner(context);
      if (code == null) throw Exception("Unexpected QR code value: aborted");

      if (code.isEmpty) {
        throw Exception('Unexpected scan QR code value: value is empty');
      }

      if (code.startsWith("monero_node:")) code = code.replaceFirst("monero_node:", "tcp://");
      if (!code.contains('://')) code = 'tcp://$code';

      final uri = Uri.tryParse(code);
      if (uri == null || uri.host.isEmpty) {
        throw Exception('Invalid QR code: Unable to parse or missing host.');
      }

      final queryParams = uri.queryParameters;
      final ipAddress = uri.host;
      final path = uri.path;
      final userInfo = uri.userInfo;
      var port = uri.hasPort ? uri.port.toString() : '';
      var rpcUser = userInfo.length == 2 ? userInfo[0] : '';
      var rpcPassword = userInfo.length == 2 ? userInfo[1] : '';

      if (rpcUser.isEmpty && rpcPassword.isEmpty) {
        rpcUser = queryParams['username'] ?? '';
        rpcPassword = queryParams['password'] ?? '';
      }

      if (port.isEmpty) {
        port = queryParams['port'] ?? '';
      }

      if (queryParams['protocol'] == 'https') {
        setSSL(true);
      }

      if (queryParams['trusted'] == 'true') {
        setTrusted(true);
      }

      await Future.delayed(Duration(milliseconds: 345));

      setAddress(ipAddress);
      setPath(path);
      setPassword(rpcPassword);
      setLogin(rpcUser);
      setPort(port);
    } on Exception catch (e) {
      connectionState = FailureState(e.toString());
    }
  }
}
