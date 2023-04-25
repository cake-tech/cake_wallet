import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:mobx/mobx.dart';

class NodeForm extends StatefulWidget {
  NodeForm({
    required this.nodeViewModel,
    required this.formKey,
    this.editingNode,
  });

  final NodeCreateOrEditViewModel nodeViewModel;
  final GlobalKey<FormState> formKey;
  final Node? editingNode;

  @override
  State<NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends State<NodeForm> {
  late final _addressController =
      TextEditingController(text: widget.editingNode?.uri.host.toString());
  late final _portController = TextEditingController(text: widget.editingNode?.uri.port.toString());
  late final _loginController = TextEditingController(text: widget.editingNode?.login);
  late final _passwordController = TextEditingController(text: widget.editingNode?.password);

  @override
  void initState() {
    super.initState();

    if (widget.editingNode != null) {
      widget.nodeViewModel
        ..setAddress((widget.editingNode!.uri.host.toString()))
        ..setPort((widget.editingNode!.uri.port.toString()))
        ..setPassword((widget.editingNode!.password ?? ''))
        ..setLogin((widget.editingNode!.login ?? ''))
        ..setSSL((widget.editingNode!.isSSL))
        ..setTrusted((widget.editingNode!.trusted));
    }
    if (widget.nodeViewModel.hasAuthCredentials) {
      reaction((_) => widget.nodeViewModel.login, (String login) {
        if (login != _loginController.text) {
          _loginController.text = login;
        }
      });

      reaction((_) => widget.nodeViewModel.password, (String password) {
        if (password != _passwordController.text) {
          _passwordController.text = password;
        }
      });
    }

    _addressController.addListener(() => widget.nodeViewModel.address = _addressController.text);
    _portController.addListener(() => widget.nodeViewModel.port = _portController.text);
    _loginController.addListener(() => widget.nodeViewModel.login = _loginController.text);
    _passwordController.addListener(() => widget.nodeViewModel.password = _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: _addressController,
                  hintText: S.of(context).node_address,
                  validator: NodeAddressValidator(),
                ),
              )
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: <Widget>[
              Expanded(
                  child: BaseTextFormField(
                controller: _portController,
                hintText: S.of(context).node_port,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                validator: NodePortValidator(),
              ))
            ],
          ),
          SizedBox(height: 10.0),
          if (widget.nodeViewModel.hasAuthCredentials) ...[
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: _loginController,
                  hintText: S.of(context).login,
                ))
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: _passwordController,
                  hintText: S.of(context).password,
                ))
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Observer(
                    builder: (_) => StandardCheckbox(
                      value: widget.nodeViewModel.useSSL,
                      onChanged: (value) => widget.nodeViewModel.useSSL = value,
                      caption: S.of(context).use_ssl,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Observer(
                    builder: (_) => StandardCheckbox(
                      value: widget.nodeViewModel.trusted,
                      onChanged: (value) => widget.nodeViewModel.trusted = value,
                      caption: S.of(context).trusted,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
