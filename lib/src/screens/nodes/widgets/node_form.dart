import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';

class NodeForm extends StatelessWidget {
  NodeForm({
    required this.nodeViewModel,
    required this.formKey,
    this.editingNode,
    required this.addressController,
    required this.portController,
    required this.loginController,
    required this.passwordController,
  });

  final NodeCreateOrEditViewModel nodeViewModel;
  final GlobalKey<FormState> formKey;
  final Node? editingNode;

  final TextEditingController addressController;
  final TextEditingController portController;
  final TextEditingController loginController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: BaseTextFormField(
                  controller: addressController,
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
                controller: portController,
                hintText: S.of(context).node_port,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                validator: NodePortValidator(),
              ))
            ],
          ),
          SizedBox(height: 10.0),
          if (nodeViewModel.hasAuthCredentials) ...[
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: loginController,
                  hintText: S.of(context).login,
                ))
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              children: <Widget>[
                Expanded(
                    child: BaseTextFormField(
                  controller: passwordController,
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
                      value: nodeViewModel.useSSL,
                      onChanged: (value) => nodeViewModel.useSSL = value,
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
                      value: nodeViewModel.trusted,
                      onChanged: (value) => nodeViewModel.trusted = value,
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
