import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/node_address_validator.dart';
import 'package:cake_wallet/core/node_port_validator.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:mobx/mobx.dart';

class RepForm extends StatelessWidget {
  RepForm({
    required this.repViewModel,
    required this.formKey,
    required this.type,
    this.editingNode,
  }) : _addressController = TextEditingController(text: editingNode?.password) {
    if (editingNode != null) {
      repViewModel..setAddress((editingNode!.password!));
    }

    _addressController.addListener(() => repViewModel.address = _addressController.text);
  }

  final NodeCreateOrEditViewModel repViewModel;
  final GlobalKey<FormState> formKey;
  final Node? editingNode;
  final CryptoCurrency type;

  final TextEditingController _addressController;

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
                  controller: _addressController,
                  hintText: S.of(context).node_address,
                  validator: AddressValidator(type: type),
                ),
              )
            ],
          ),
          SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
