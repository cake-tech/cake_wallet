import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
          vm.updateViewModelFromText(item.keyValue, text);
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

  final NodeCreateOrEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: widget.formKey,
        child: NewListSections(
          sections: vm.nodeFormItems,
          controllers: _controllers,
          getCheckboxValue: vm.getCheckboxValue,
          updateCheckboxValue: vm.updateCheckboxValue,
          tapHandlers: tapHandlers
        ));
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
}
