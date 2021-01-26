import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class AddressPage extends StatelessWidget {
  AddressPage({@required this.addressListViewModel})
      : _cryptoAmountFocus = FocusNode();

  final WalletAddressListViewModel addressListViewModel;

  final FocusNode _cryptoAmountFocus;

  @override
  Widget build(BuildContext context) {
    return KeyboardActions(
        autoScroll: false,
        disableScroll: true,
        tapOutsideToDismiss: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor:
                Theme.of(context).accentTextTheme.body2.backgroundColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _cryptoAmountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              )
            ]),
        child: Container(
          height: 1,
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Center(
                child: Observer(builder: (_) => QRWidget(
                    addressListViewModel: addressListViewModel,
                    amountTextFieldFocusNode: _cryptoAmountFocus,
                    isAmountFieldShow: !addressListViewModel.hasAccounts)),
              )),
              Observer(builder: (_) {
                return addressListViewModel.hasAddressList
                    ? GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(Routes.receive),
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.only(left: 24, right: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25)),
                              border: Border.all(
                                  color:
                                      Theme.of(context).textTheme.subhead.color,
                                  width: 1),
                              color: Theme.of(context).buttonColor),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Observer(
                                  builder: (_) => Text(
                                        addressListViewModel.hasAccounts
                                            ? S
                                                .of(context)
                                                .accounts_subaddresses
                                            : S.of(context).addresses,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .display3
                                                .backgroundColor),
                                      )),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display3
                                    .backgroundColor,
                              )
                            ],
                          ),
                        ),
                      )
                    : PrimaryButton(
                        onPressed: () => addressListViewModel.nextAddress(),
                        text: 'Next address',
                        color: Theme.of(context).buttonColor,
                        textColor: Theme.of(context)
                            .accentTextTheme
                            .display3
                            .backgroundColor);
              })
            ],
          ),
        ));
  }
}
