import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';

class LightningReceiveOnchainPage extends BasePage {
  LightningReceiveOnchainPage({required this.addressListViewModel, required this.receiveOptionViewModel})
      : _cryptoAmountFocus = FocusNode(),
        _amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _amountController.addListener(() {
      if (_formKey.currentState!.validate()) {
        addressListViewModel.changeAmount(_amountController.text);
      }
    });
  }

  final WalletAddressListViewModel addressListViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final TextEditingController _amountController;
  final GlobalKey<FormState> _formKey;
  static const _heroTag = 'receive_page';

  @override
  String get title => S.current.receive;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => true;

  final FocusNode _cryptoAmountFocus;

  // @override
  // Widget middle(BuildContext context) {
  //   return Text(
  //     title,
  //     style: TextStyle(
  //         fontSize: 18.0,
  //         fontWeight: FontWeight.bold,
  //         fontFamily: 'Lato',
  //         color: pageIconColor(context)),
  //   );
  // }

  @override
  Widget middle(BuildContext context) => PresentReceiveOptionPicker(
      color: titleColor(context), receiveOptionViewModel: receiveOptionViewModel);

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  Widget body(BuildContext context) {
    return SizedBox();
  }
}
