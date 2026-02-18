import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/core/socks_proxy_node_address_validator.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobx/mobx.dart';

class NodeForm extends StatefulWidget {
  NodeForm({
    super.key,
    required this.nodeViewModel,
  });

  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  State<StatefulWidget> createState() => NodeFormState(vm: nodeViewModel);
}

class NodeFormState extends State<NodeForm> {
  NodeFormState({required this.vm});

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();

    for(final key in vm.textFieldKeys) {
      _controllers[key] = TextEditingController();

      _controllers[key]!.addListener(() {
        final text = _controllers[key]!.text;
        vm.updateViewModelFromText(key, text);
      });
    }

    _setupReactions();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  final NodeCreateOrEditViewModel vm;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_)=>Form(
        key: _formKey,
        child: NewListSections(
          sections:  {
            'main': [
              ListItemTextField(
                keyValue: vm.nodeLabelUIKey,
                label: 'Node label',
                initialValue: vm.label,
              ),
              ListItemTextField(
                keyValue: vm.nodeAddressUIKey,
                label: S.current.node_address,
                initialValue: vm.address,
                validator: vm.walletType == WalletType.decred
                    ? NodeAddressValidatorDecredBlankException()
                    : NodeAddressValidator(),
              ),
              if (vm.hasPathSupport)
                ListItemTextField(
                  keyValue: vm.nodePathUIKey,
                  label: '/path',
                  initialValue: vm.path,
                  validator: NodePathValidator(),
                ),
              ListItemTextField(
                keyValue: vm.nodePortUIKey,
                label: S.current.node_port,
                initialValue: '',
                //keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                validator: NodePortValidator(),
              ),
              if (vm.hasAuthCredentials) ...[
                ListItemTextField(
                  keyValue: vm.nodeUsernameUIKey,
                  label: S.current.login,
                  initialValue: vm.login,
                ),
                ListItemTextField(
                  keyValue: vm.nodePasswordUIKey,
                  label: S.current.password,
                  initialValue: vm.password,
                ),
              ]
            ],
            'advanced': [
              ListItemCheckbox(
                  keyValue: vm.useSSLUIKey,
                  label: S.current.use_ssl,
                  value: vm.useSSL,
                  onChanged: (value) => vm.useSSL = value),
              ListItemCheckbox(
                keyValue: vm.nodeTrustedUIKey,
                label: S.current.trusted,
                value: vm.trusted,
                onChanged: (value) => vm.trusted = value,
              ),
              if (vm.usesEmbeddedProxy)
                ListItemCheckbox(
                  keyValue: vm.nodeEmbeddedTorProxyUIKey,
                  label: 'Embedded Tor SOCKS Proxy',
                  value: vm.usesEmbeddedProxy,
                  onChanged: (_) {},
                ),
              ListItemCheckbox(
                keyValue: vm.useSocksProxyUIKey,
                label: 'Use SOCKS Proxy',
                value: vm.useSocksProxy,
                onChanged: (value) {
                  vm.socksProxyAddress = '';
                  vm.useSocksProxy = value;
                },
              ),
              if (vm.useSocksProxy)
                ListItemTextField(
                  keyValue: vm.socksProxyAddressUIKey,
                  label: 'host:port',
                  initialValue: vm.socksProxyAddress,
                  validator: SocksProxyNodeAddressValidator(),
                ),
              ListItemCheckbox(
                  keyValue: vm.autoSwitchingUIKey,
                  label: S.current.enable_for_auto_switching,
                  value: vm.isEnabledForAutoSwitching,
                  onChanged: (value) => vm.isEnabledForAutoSwitching = value),
            ],
          },
          controllers: _controllers,
          getCheckboxValue: vm.getCheckboxValue,
          updateCheckboxValue: vm.updateCheckboxValue,
          tapHandlers: tapHandlers
        ),
      ),
    );
  }

  Map<String, VoidCallback> get tapHandlers => {
    'node_regular_with_drill_in_row_key': () => _showToast('Regular with drill-in row tapped'),
    'node_tall_row_key': () => _showToast('Tall row tapped'),
    'node_regular_with_trailing_row_key': () => _showToast('Regular with trailing row tapped'),
    'node_item_selector_row_key': () => _showToast('Item selector row tapped'),
  };

  void _showToast(String msg) async {
    try {
      await Fluttertoast.showToast(
        msg: msg,
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.85),
      );
    } catch (_) {}
  }


  void _setupReactions() {
    _bindController(() => vm.label, vm.nodeLabelUIKey);
    _bindController(() => vm.address, vm.nodeAddressUIKey);
    _bindController(() => vm.port, vm.nodePortUIKey);
    _bindController(() => vm.path, vm.nodePathUIKey);

    if (vm.hasAuthCredentials) {
      _bindController(() => vm.login, vm.nodeUsernameUIKey);
      _bindController(() => vm.password, vm.nodePasswordUIKey);
    }

    if (vm.hasPathSupport) {
      _bindController(() => vm.path, vm.nodePathUIKey);
    }

    _bindController(
      () => vm.socksProxyAddress,
      vm.socksProxyAddressUIKey,
    );
  }

  void _bindController<T>(
    T Function() observe,
    String uiKey,
  ) {
    reaction<T>((_) => observe(), (value) {
      final controller = _controllers[uiKey];
      if (controller != null && controller.text != value.toString()) {
        controller.text = value.toString();
      }
    });
  }

  bool validate() => _formKey.currentState?.validate() ?? false;
}
