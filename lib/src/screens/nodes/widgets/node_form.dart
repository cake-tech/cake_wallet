import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

class NodeForm extends StatefulWidget {
  NodeForm({
    required this.nodeViewModel,
    required this.formKey,
  });

  final NodeCreateOrEditViewModel nodeViewModel;
  final GlobalKey<FormState> formKey;

  @override
  State<StatefulWidget> createState() => _NodeFormState(vm: nodeViewModel);
}

class _NodeFormState extends State<NodeForm> {
  _NodeFormState({required this.vm});

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();

    vm.nodeFormItems.forEach((section, items) {
      for (final item in items.whereType<ListItemTextField>()) {
        final controller = TextEditingController(text: item.initialValue ?? '');

        _controllers[item.keyValue] = controller;

        controller.addListener(() {
          final text = controller.text;
          item.onChanged?.call(text);
          _updateViewModelFromText(item.keyValue, text);
        });
      }
    });

    _setupReactions();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateViewModelFromText(String key, String value) {
    if (key == vm.nodeLabelUIKey) vm.setLabel(value);
    if (key == vm.nodeAddressUIKey) vm.setAddress(value);
    if (key == vm.nodePortUIKey) vm.setPort(value);
    if (key == vm.nodePathUIKey) vm.setPath(value);
    if (key == vm.nodeUsernameUIKey) vm.setLogin(value);
    if (key == vm.nodePasswordUIKey) vm.setPassword(value);
    if (key == vm.socksProxyAddressUIKey) vm.setSocksProxyAddress(value);
  }

  bool _getCheckboxValue(String key) {
    if (key == vm.useSSLUIKey) return vm.useSSL;
    if (key == vm.nodeTrustedUIKey) return vm.trusted;
    if (key == vm.nodeEmbeddedTorProxyUIKey) {
      return vm.usesEmbeddedProxy;
    }
    if (key == vm.useSocksProxyUIKey) {
      return vm.useSocksProxy;
    }
    if (key == vm.autoSwitchingUIKey) {
      return vm.isEnabledForAutoSwitching;
    }
    return false;
  }

  void _updateCheckboxValue(String key, bool value) {
    if (key == vm.useSSLUIKey) vm.useSSL = value;
    if (key == vm.nodeTrustedUIKey) vm.trusted = value;
    if (key == vm.useSocksProxyUIKey) vm.useSocksProxy = value;
    if (key == vm.autoSwitchingUIKey) vm.isEnabledForAutoSwitching = value;
  }

  final NodeCreateOrEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: widget.formKey,
        child: NewListSections(
          sections: vm.nodeFormItems,
          controllers: _controllers,
          getCheckboxValue: _getCheckboxValue,
          updateCheckboxValue: _updateCheckboxValue,
        ));
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
}
