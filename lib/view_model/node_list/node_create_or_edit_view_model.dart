import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/core/socks_proxy_node_address_validator.dart';
import 'package:cake_wallet/entities/new_ui_entities/new_list_row_item.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/new_list_row.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:collection/collection.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';

part 'node_create_or_edit_view_model.g.dart';

class NodeCreateOrEditViewModel = NodeCreateOrEditViewModelBase
    with _$NodeCreateOrEditViewModel;

abstract class NodeCreateOrEditViewModelBase with Store {
  NodeCreateOrEditViewModelBase(
      this._nodeSource, this._walletType, this.editingNode, this._settingsStore)
      : state = InitialExecutionState(),
        connectionState = InitialExecutionState(),
        label = editingNode?.label ?? '',
        address = editingNode?.uri.host.toString() ?? '',
        path = editingNode?.path.toString() ?? '',
        port = (editingNode != null && editingNode.uri.hasPort)
            ? editingNode.uri.port.toString()
            : '',
        login = editingNode?.login ?? '',
        password = editingNode?.password ?? '',
        socksProxyAddress = editingNode?.socksProxyAddress ?? '',
        trusted = editingNode?.trusted ?? false,
        isEnabledForAutoSwitching =
            editingNode?.isEnabledForAutoSwitching ?? false,
        useSocksProxy = editingNode?.socksProxyAddress != null &&
            editingNode!.socksProxyAddress!.isNotEmpty,
        useSSL = editingNode?.useSSL ?? false {
    nodeFormItems = {
      'main': [
        NewListRowItem(
          key: nodeLabelUIKey,
          label: 'Node label',
          type: NewListRowType.textFormField,
          initialValue: label,
        ),
        NewListRowItem(
          key: nodeAddressUIKey,
          label: S.current.node_address,
          type: NewListRowType.textFormField,
          initialValue: address,
          validator: _walletType == WalletType.decred
              ? NodeAddressValidatorDecredBlankException()
              : NodeAddressValidator(),
        ),
        if (hasPathSupport)
          NewListRowItem(
            key: nodePathUIKey,
            label: '/path',
            type: NewListRowType.textFormField,
            initialValue: path,
            validator: NodePathValidator(),
          ),
        NewListRowItem(
          key: nodePortUIKey,
          label: S.current.node_port,
          type: NewListRowType.textFormField,
          initialValue: '',
          //keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
          validator: NodePortValidator(),
        ),
        if (hasAuthCredentials) ...[
          NewListRowItem(
            key: nodeUsernameUIKey,
            label: S.current.login,
            type: NewListRowType.textFormField,
            initialValue: login,
          ),
          NewListRowItem(
            key: nodePasswordUIKey,
            label: S.current.password,
            type: NewListRowType.textFormField,
            initialValue: password,
          ),
        ]
      ],
      'advanced': [
        NewListRowItem(
            key: useSSLUIKey,
            label: S.current.use_ssl,
            type: NewListRowType.checkbox,
            checkboxValue: useSSL,
            onCheckboxChanged: (value) => useSSL = value),
        NewListRowItem(
          key: nodeTrustedUIKey,
          label: S.current.trusted,
          type: NewListRowType.checkbox,
          checkboxValue: trusted,
          onCheckboxChanged: (value) => trusted = value,
        ),
        if (usesEmbeddedProxy)
          NewListRowItem(
            key: nodeEmbeddedTorProxyUIKey,
            label: 'Embedded Tor SOCKS Proxy',
            type: NewListRowType.checkbox,
            checkboxValue: usesEmbeddedProxy,
            onCheckboxChanged: null,
          ),
        NewListRowItem(
          key: useSocksProxyUIKey,
          label: 'Use SOCKS Proxy',
          type: NewListRowType.checkbox,
          checkboxValue: useSocksProxy,
          onCheckboxChanged: (value) {
            socksProxyAddress = '';
            useSocksProxy = value;
          },
        ),
        if (useSocksProxy)
          NewListRowItem(
            key: socksProxyAddressUIKey,
            label: '[<ip>:]<port>',
            type: NewListRowType.textFormField,
            initialValue: socksProxyAddress,
            validator: SocksProxyNodeAddressValidator(),
          ),
        NewListRowItem(
            key: autoSwitchingUIKey,
            label: S.current.enable_for_auto_switching,
            type: NewListRowType.checkbox,
            checkboxValue: isEnabledForAutoSwitching,
            onCheckboxChanged: (value) => isEnabledForAutoSwitching = value),
      ]
    };
  }

  final nodeLabelUIKey = 'node_label_row_key';
  final nodeAddressUIKey = 'node_address_row_key';
  final nodePathUIKey = 'node_path_row_key';
  final nodeUsernameUIKey = 'node_username_row_key';
  final nodePasswordUIKey = 'node_password_row_key';
  final nodePortUIKey = 'node_port_row_key';
  final useSSLUIKey = 'node_use_ssl_row_key';
  final nodeTrustedUIKey = 'node_trusted_daemon_row_key';
  final nodeEmbeddedTorProxyUIKey = 'node_embedded_tor_proxy_row_key';
  final autoSwitchingUIKey = 'node_auto_switching_row_key';
  final useSocksProxyUIKey = 'node_use_socks_proxy_row_key';
  final socksProxyAddressUIKey = 'node_socks_proxy_address_row_key';

  Map<String, List<NewListRowItem>> nodeFormItems = {};

  @observable
  ExecutionState state;

  @observable
  String label;

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

  @computed
  bool get isReady =>
      (address.isNotEmpty) ||
      _walletType == WalletType.decred; // Allow an empty address.

  bool get hasAuthCredentials =>
      _walletType == WalletType.monero ||
      _walletType == WalletType.wownero ||
      _walletType == WalletType.haven;

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
  final Node? editingNode;
  final Box<Node> _nodeSource;
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
  void setIsEnabledForAutoSwitching(bool val) =>
      isEnabledForAutoSwitching = val;

  @action
  void setSocksProxy(bool val) => useSocksProxy = val;

  @action
  void setSocksProxyAddress(String val) => socksProxyAddress = val;

  @action
  Future<void> save({Node? editingNode, bool saveAsCurrent = false}) async {
    final node = Node(
        label: label,
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
      state = IsExecutingState();
      if (editingNode != null) {
        await _nodeSource.put(editingNode.key, node);
      } else if (_existingNode(node) != null) {
        setAsCurrent(_existingNode(node)!);
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

  Node? _existingNode(Node node) {
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

      if (code.startsWith("monero_node:"))
        code = code.replaceFirst("monero_node:", "tcp://");
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
