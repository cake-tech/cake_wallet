import 'package:cake_wallet/src/widgets/new_list_row.dart';
import 'package:cake_wallet/src/widgets/new_list_section.dart';
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
  State<StatefulWidget> createState() =>
      _NodeFormState(nodeViewModel: nodeViewModel);
}

class _NodeFormState extends State<NodeForm> {
  _NodeFormState({required this.nodeViewModel});

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();

    nodeViewModel.nodeFormItems.forEach((section, items) {
      for (final item in items) {
        if (item.type == NewListRowType.textFormField) {
          _controllers[item.key] =
              TextEditingController(text: item.initialValue);
          _controllers[item.key]!.addListener(() {
            _updateViewModelFromText(item.key, _controllers[item.key]!.text);
          });
        }
      }
    });

    _setupReactions();
  }

  void _updateViewModelFromText(String key, String value) {
    if (key == nodeViewModel.nodeLabelUIKey) nodeViewModel.label = value;
    if (key == nodeViewModel.nodeAddressUIKey) nodeViewModel.address = value;
    if (key == nodeViewModel.nodePortUIKey) nodeViewModel.port = value;
    if (key == nodeViewModel.nodePathUIKey) nodeViewModel.path = value;
    if (key == nodeViewModel.nodeUsernameUIKey) nodeViewModel.login = value;
    if (key == nodeViewModel.nodePasswordUIKey) nodeViewModel.password = value;
    if (key == nodeViewModel.socksProxyAddressUIKey) {
      nodeViewModel.socksProxyAddress = value;
    }
  }

  bool _getCheckboxValue(String key) {
    if (key == nodeViewModel.useSSLUIKey) return nodeViewModel.useSSL;
    if (key == nodeViewModel.nodeTrustedUIKey) return nodeViewModel.trusted;
    if (key == nodeViewModel.nodeEmbeddedTorProxyUIKey) {
      return nodeViewModel.usesEmbeddedProxy;
    }
    if (key == nodeViewModel.useSocksProxyUIKey) {
      return nodeViewModel.useSocksProxy;
    }
    if (key == nodeViewModel.autoSwitchingUIKey) {
      return nodeViewModel.isEnabledForAutoSwitching;
    }
    return false;
  }

  void _updateCheckboxValue(String key, bool value) {
    if (key == nodeViewModel.useSSLUIKey) {
      nodeViewModel.useSSL = value;
    }
    if (key == nodeViewModel.nodeTrustedUIKey) {
      nodeViewModel.trusted = value;
    }
    if (key == nodeViewModel.useSocksProxyUIKey) {
      nodeViewModel.useSocksProxy = value;
    }
    if (key == nodeViewModel.autoSwitchingUIKey) {
      nodeViewModel.isEnabledForAutoSwitching = value;
    }
  }

  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: NewListSections(
        sections: nodeViewModel.nodeFormItems,
        controllers: _controllers,
        getCheckboxValue: _getCheckboxValue,
        updateCheckboxValue: _updateCheckboxValue,
      ),
    );
  }

  void _setupReactions() {
    _bindController(() => nodeViewModel.label, nodeViewModel.nodeLabelUIKey);
    _bindController(
        () => nodeViewModel.address, nodeViewModel.nodeAddressUIKey);
    _bindController(() => nodeViewModel.port, nodeViewModel.nodePortUIKey);
    _bindController(() => nodeViewModel.path, nodeViewModel.nodePathUIKey);

    if (nodeViewModel.hasAuthCredentials) {
      _bindController(
          () => nodeViewModel.login, nodeViewModel.nodeUsernameUIKey);
      _bindController(
          () => nodeViewModel.password, nodeViewModel.nodePasswordUIKey);
    }

    if (nodeViewModel.hasPathSupport) {
      _bindController(() => nodeViewModel.path, nodeViewModel.nodePathUIKey);
    }

    _bindController(
      () => nodeViewModel.socksProxyAddress,
      nodeViewModel.socksProxyAddressUIKey,
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
