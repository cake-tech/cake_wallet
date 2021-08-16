import 'dart:ui';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/send/widgets/parse_address_from_domain_alert.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class SendCard extends StatefulWidget {
  SendCard({Key key, @required this.output, @required this.sendViewModel}) : super(key: key);

  final Output output;
  final SendViewModel sendViewModel;

  @override
  SendCardState createState() => SendCardState(
    output: output,
    sendViewModel: sendViewModel
  );
}

class SendCardState extends State<SendCard>
    with AutomaticKeepAliveClientMixin<SendCard> {
  SendCardState({@required this.output, @required this.sendViewModel})
      : addressController = TextEditingController(),
        cryptoAmountController = TextEditingController(),
        fiatAmountController = TextEditingController(),
        noteController = TextEditingController(),
        cryptoAmountFocus = FocusNode(),
        fiatAmountFocus = FocusNode(),
        addressFocusNode = FocusNode();

  static const prefixIconWidth = 34.0;
  static const prefixIconHeight = 34.0;

  final Output output;
  final SendViewModel sendViewModel;

  final TextEditingController addressController;
  final TextEditingController cryptoAmountController;
  final TextEditingController fiatAmountController;
  final TextEditingController noteController;
  final FocusNode cryptoAmountFocus;
  final FocusNode fiatAmountFocus;
  final FocusNode addressFocusNode;

  bool _effectsInstalled = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setEffects(context);

    return Stack(
      children: [
        KeyboardActions(
            config: KeyboardActionsConfig(
                keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                keyboardBarColor: Theme.of(context).accentTextTheme.body2
                    .backgroundColor,
                nextFocus: false,
                actions: [
                  KeyboardActionsItem(
                    focusNode: cryptoAmountFocus,
                    toolbarButtons: [(_) => KeyboardDoneButton()],
                  ),
                  KeyboardActionsItem(
                    focusNode: fiatAmountFocus,
                    toolbarButtons: [(_) => KeyboardDoneButton()],
                  )
                ]),
            child: Container(
              height: 0,
              color: Colors.transparent,
            )),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24)),
            gradient: LinearGradient(colors: [
              Theme.of(context).primaryTextTheme.subhead.color,
              Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .decorationColor,
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 100, 24, 32),
            child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AddressTextField(
                      focusNode: addressFocusNode,
                      controller: addressController,
                      onURIScanned: (uri) {
                        var address = '';
                        var amount = '';

                        if (uri != null) {
                          address = uri.path;
                          amount = uri.queryParameters['tx_amount'] ??
                              uri.queryParameters['amount'];
                        } else {
                          address = uri.toString();
                        }

                        addressController.text = address;
                        cryptoAmountController.text = amount;
                      },
                      options: [
                        AddressTextFieldOption.paste,
                        AddressTextFieldOption.qrCode,
                        AddressTextFieldOption.addressBook
                      ],
                      buttonColor: Theme.of(context)
                          .primaryTextTheme
                          .display1
                          .color,
                      borderColor: Theme.of(context)
                          .primaryTextTheme
                          .headline
                          .color,
                      textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                      hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline
                              .decorationColor),
                      onPushPasteButton: (context) async {
                        final parsedAddress =
                        await output.applyOpenaliasOrUnstoppableDomains();
                        showAddressAlert(context, parsedAddress);
                      },
                      validator: sendViewModel.addressValidator,
                    ),
                    Observer(
                        builder: (_) => Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Stack(
                                children: [
                                  BaseTextFormField(
                                      focusNode: cryptoAmountFocus,
                                      controller: cryptoAmountController,
                                      keyboardType:
                                      TextInputType.numberWithOptions(
                                          signed: false, decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))
                                      ],
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(top: 9),
                                        child: Text(
                                            sendViewModel.currency.title +
                                                ':',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            )),
                                      ),
                                      suffixIcon: SizedBox(
                                        width: prefixIconWidth,
                                      ),
                                      hintText: '0.0000',
                                      borderColor: Theme.of(context)
                                          .primaryTextTheme
                                          .headline
                                          .color,
                                      textStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                      placeholderTextStyle: TextStyle(
                                          color: Theme.of(context)
                                              .primaryTextTheme
                                              .headline
                                              .decorationColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14),
                                      validator: output.sendAll
                                          ? sendViewModel.allAmountValidator
                                          : sendViewModel
                                          .amountValidator),
                                  if (!sendViewModel.isBatchSending) Positioned(
                                      top: 2,
                                      right: 0,
                                      child: Container(
                                          width: prefixIconWidth,
                                          height: prefixIconHeight,
                                          child: InkWell(
                                              onTap: () async =>
                                                  output.setSendAll(),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryTextTheme
                                                        .display1
                                                        .color,
                                                    borderRadius:
                                                    BorderRadius.all(
                                                        Radius.circular(6))),
                                                child: Center(
                                                    child: Text(
                                                        S.of(context).all,
                                                        textAlign:
                                                        TextAlign.center,
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            color:
                                                            Theme.of(context)
                                                                .primaryTextTheme
                                                                .display1
                                                                .decorationColor))),
                                              ))))])
                        )),
                    Observer(
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                  child: Text(
                                    S.of(context).available_balance +
                                        ':',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .headline
                                            .decorationColor),
                                  )),
                              Text(
                                sendViewModel.balance,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .headline
                                        .decorationColor),
                              )
                            ],
                          ),
                        )),
                    Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: BaseTextFormField(
                          focusNode: fiatAmountFocus,
                          controller: fiatAmountController,
                          keyboardType:
                          TextInputType.numberWithOptions(
                              signed: false, decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))
                          ],
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(top: 9),
                            child:
                            Text(sendViewModel.fiat.title + ':',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                          ),
                          hintText: '0.00',
                          borderColor: Theme.of(context)
                              .primaryTextTheme
                              .headline
                              .color,
                          textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                          placeholderTextStyle: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .headline
                                  .decorationColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                        )),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: BaseTextFormField(
                        controller: noteController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        borderColor: Theme.of(context)
                            .primaryTextTheme
                            .headline
                            .color,
                        textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                        hintText: S.of(context).note_optional,
                        placeholderTextStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .headline
                                .decorationColor),
                      ),
                    ),
                    Observer(
                        builder: (_) => GestureDetector(
                          onTap: () =>
                              _setTransactionPriority(context),
                          child: Container(
                            padding: EdgeInsets.only(top: 24),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    S
                                        .of(context)
                                        .send_estimated_fee,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w500,
                                        //color: Theme.of(context).primaryTextTheme.display2.color,
                                        color: Colors.white)),
                                Container(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                              output
                                                  .estimatedFee
                                                  .toString() +
                                                  ' ' +
                                                  sendViewModel
                                                      .currency.title,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  //color: Theme.of(context).primaryTextTheme.display2.color,
                                                  color:
                                                  Colors.white)),
                                          Padding(
                                              padding:
                                              EdgeInsets.only(top: 5),
                                              child: Text(
                                                  output
                                                      .estimatedFeeFiatAmount
                                                      +  ' ' +
                                                      sendViewModel
                                                          .fiat.title,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color: Theme
                                                          .of(context)
                                                          .primaryTextTheme
                                                          .headline
                                                          .decorationColor))
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: 2,
                                            left: 5),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        )),
                    if (sendViewModel.isElectrumWallet) Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushNamed(Routes.unspentCoinsList),
                            child: Container(
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        S.of(context).coin_control,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  ],
                                )
                            )
                        )
                    )
                  ],
                )
            ),
          ),
        )
      ],
    );
  }

  void _setEffects(BuildContext context) {
    addressController.text = output.address;
    cryptoAmountController.text = output.cryptoAmount;
    fiatAmountController.text = output.fiatAmount;
    noteController.text = output.note;

    if (_effectsInstalled) {
      return;
    }

    cryptoAmountController.addListener(() {
      final amount = cryptoAmountController.text;

      if (output.sendAll && amount != S.current.all) {
        output.sendAll = false;
      }

      if (amount != output.cryptoAmount) {
        output.setCryptoAmount(amount);
      }
    });

    fiatAmountController.addListener(() {
      final amount = fiatAmountController.text;

      if (amount != output.fiatAmount) {
        output.sendAll = false;
        output.setFiatAmount(amount);
      }
    });

    noteController.addListener(() {
      final note = noteController.text ?? '';

      if (note != output.note) {
        output.note = note;
      }
    });

    reaction((_) => output.sendAll, (bool all) {
      if (all) {
        cryptoAmountController.text = S.current.all;
        fiatAmountController.text = null;
      }
    });

    reaction((_) => output.fiatAmount, (String amount) {
      if (amount != fiatAmountController.text) {
        fiatAmountController.text = amount;
      }
    });

    reaction((_) => output.cryptoAmount, (String amount) {
      if (output.sendAll && amount != S.current.all) {
        output.sendAll = false;
      }

      if (amount != cryptoAmountController.text) {
        cryptoAmountController.text = amount;
      }
    });

    reaction((_) => output.address, (String address) {
      if (address != addressController.text) {
        addressController.text = address;
      }
    });

    addressController.addListener(() {
      final address = addressController.text;

      if (output.address != address) {
        output.address = address;
      }
    });

    reaction((_) => output.note, (String note) {
      if (note != noteController.text) {
        noteController.text = note;
      }
    });

    addressFocusNode.addListener(() async {
      if (!addressFocusNode.hasFocus && addressController.text.isNotEmpty) {
        final parsedAddress = await output.applyOpenaliasOrUnstoppableDomains();
        showAddressAlert(context, parsedAddress);
      }
    });

    _effectsInstalled = true;
  }

  Future<void> _setTransactionPriority(BuildContext context) async {
    final items = priorityForWalletType(sendViewModel.walletType);
    final selectedItem = items.indexOf(sendViewModel.transactionPriority);

    await showPopUp<void>(
        builder: (_) => Picker(
          items: items,
          displayItem: sendViewModel.displayFeeRate,
          selectedAtIndex: selectedItem,
          title: S.of(context).please_select,
          mainAxisAlignment: MainAxisAlignment.center,
          onItemSelected: (TransactionPriority priority) =>
              sendViewModel.setTransactionPriority(priority),
        ),
        context: context);
  }

  @override
  bool get wantKeepAlive => true;
}