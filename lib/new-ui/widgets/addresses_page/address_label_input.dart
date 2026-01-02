import 'dart:ui';

import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_edit_or_create_view_model.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';



class AddressLabelInputPopup extends StatefulWidget {
  const AddressLabelInputPopup({super.key, required this.walletAddressEditOrCreateViewModel, });

  final WalletAddressEditOrCreateViewModel walletAddressEditOrCreateViewModel;

  @override
  State<AddressLabelInputPopup> createState() => _AddressLabelInputPopupState();
}

class _AddressLabelInputPopupState extends State<AddressLabelInputPopup> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();


    reaction((_) => widget.walletAddressEditOrCreateViewModel.state, (AddressEditOrCreateState state) {
      if (state is AddressSavedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).pop(widget.walletAddressEditOrCreateViewModel.label);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.text = widget.walletAddressEditOrCreateViewModel.label;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [Padding(
          padding: const EdgeInsets.all(16.0),
          child: NewListSections(sections: {"":[
            ListItemTextField(keyValue: "label", label: "Label", focusNode:_focusNode,onFieldSubmitted: (value){
              widget.walletAddressEditOrCreateViewModel.label = value;
              widget.walletAddressEditOrCreateViewModel.save();
              // Navigator.of(context).pop();
            })
          ]},
            controllers: {"label": _controller},
          ),
        ),]
      ),
    );
  }
}
