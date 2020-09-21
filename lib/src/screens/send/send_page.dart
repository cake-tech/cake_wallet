import 'dart:ui';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/top_panel.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:dotted_border/dotted_border.dart';

class SendPage extends BasePage {
  SendPage({@required this.sendViewModel});

  final SendViewModel sendViewModel;
  final _addressController = TextEditingController();
  final _cryptoAmountController = TextEditingController();
  final _fiatAmountController = TextEditingController();
  final _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _effectsInstalled = false;

  @override
  String get title => S.current.send;

  @override
  Color get titleColor => Colors.white;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget trailing(context) => TrailButton(
      caption: S.of(context).clear, onPressed: () => sendViewModel.reset());

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
        body: Container(
            color: Theme.of(context).backgroundColor, child: body(context)));
  }

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.only(bottom: 24),
      content: Column(
        children: <Widget>[
          TopPanel(
            edgeInsets: EdgeInsets.all(0),
            gradient: LinearGradient(colors: [
              Theme.of(context).primaryTextTheme.subhead.color,
              Theme.of(context).primaryTextTheme.subhead.decorationColor,
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            widget: Form(
              key: _formKey,
              child: Column(children: <Widget>[
                CupertinoNavigationBar(
                  leading: leading(context),
                  middle: middle(context),
                  trailing: trailing(context),
                  backgroundColor: Colors.transparent,
                  border: null,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: <Widget>[
                      AddressTextField(
                        controller: _addressController,
                        focusNode: _focusNode,
                        onURIScanned: (uri) {
                          var address = '';
                          var amount = '';

                          if (uri != null) {
                            address = uri.path;
                            amount = uri.queryParameters['tx_amount'];
                          } else {
                            address = uri.toString();
                          }

                          _addressController.text = address;
                          _cryptoAmountController.text = amount;
                        },
                        options: [
                          AddressTextFieldOption.paste,
                          AddressTextFieldOption.qrCode,
                          AddressTextFieldOption.addressBook
                        ],
                        buttonColor:
                        Theme.of(context).primaryTextTheme.display1.color,
                        borderColor:
                        Theme.of(context).primaryTextTheme.headline.color,
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
                        validator: sendViewModel.addressValidator,
                      ),
                      Observer(builder: (_) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: BaseTextFormField(
                                controller: _cryptoAmountController,
                                keyboardType: TextInputType.numberWithOptions(
                                    signed: false, decimal: true),
                                inputFormatters: [
                                  BlacklistingTextInputFormatter(
                                      RegExp('[\\-|\\ |\\,]'))
                                ],
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(top: 9),
                                  child:
                                  Text(sendViewModel.currency.title + ':',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )),
                                ),
                                suffixIcon: Container(
                                  height: 32,
                                  width: 32,
                                  margin: EdgeInsets.only(
                                      left: 14, top: 4, bottom: 10),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .display1
                                          .color,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(6))),
                                  child: InkWell(
                                    onTap: () =>
                                        sendViewModel.setSendAll(),
                                    child: Center(
                                      child: Text(S.of(context).all,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryTextTheme
                                                  .display1
                                                  .decorationColor)),
                                    ),
                                  ),
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
                                validator: sendViewModel.amountValidator));
                      }),
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
                                      S.of(context).available_balance + ':',
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
                            controller: _fiatAmountController,
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              BlacklistingTextInputFormatter(
                                  RegExp('[\\-|\\ |\\,]'))
                            ],
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(top: 9),
                              child: Text(sendViewModel.fiat.title + ':',
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
                      Observer(
                          builder: (_) => GestureDetector(
                            onTap: () =>
                                _setTransactionPriority(context),
                            child: Container(
                              padding: EdgeInsets.only(top: 24),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(S.of(context).send_estimated_fee,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          //color: Theme.of(context).primaryTextTheme.display2.color,
                                          color: Colors.white)),
                                  Container(
                                    child: Row(
                                      children: <Widget>[
                                        Text(
                                            sendViewModel.estimatedFee
                                                .toString() +
                                                ' ' +
                                                sendViewModel
                                                    .currency.title,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                FontWeight.w600,
                                                //color: Theme.of(context).primaryTextTheme.display2.color,
                                                color: Colors.white)),
                                        Padding(
                                          padding:
                                          EdgeInsets.only(left: 5),
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
                          ))
                    ],
                  ),
                )
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 30, left: 24, bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  S.of(context).send_templates,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .primaryTextTheme
                          .display4
                          .color),
                )
              ],
            ),
          ),
          Container(
            height: 40,
            width: double.infinity,
            padding: EdgeInsets.only(left: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamed(Routes.sendTemplate),
                    child: Container(
                      padding: EdgeInsets.only(left: 1, right: 10),
                      child: DottedBorder(
                          borderType: BorderType.RRect,
                          dashPattern: [6, 4],
                          color: Theme.of(context)
                              .primaryTextTheme
                              .display2
                              .decorationColor,
                          strokeWidth: 2,
                          radius: Radius.circular(20),
                          child: Container(
                            height: 34,
                            width: 75,
                            padding: EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.all(Radius.circular(20)),
                              color: Colors.transparent,
                            ),
                            child: Text(
                              S.of(context).send_new,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .display3
                                      .color),
                            ),
                          )),
                    ),
                  ),
                  // Observer(
                  //     builder: (_) {
                  //       final templates = sendViewModel.templates;
                  //       final itemCount = templates.length;

                  //       return ListView.builder(
                  //           scrollDirection: Axis.horizontal,
                  //           shrinkWrap: true,
                  //           physics: NeverScrollableScrollPhysics(),
                  //           itemCount: itemCount,
                  //           itemBuilder: (context, index) {
                  //             final template = templates[index];

                  //             return TemplateTile(
                  //               key: UniqueKey(),
                  //               to: template.name,
                  //               amount: template.amount,
                  //               from: template.cryptoCurrency,
                  //               onTap: () {
                  //                 _addressController.text = template.address;
                  //                 _cryptoAmountController.text = template.amount;
                  //                 getOpenaliasRecord(context);
                  //               },
                  //               onRemove: () {
                  //                 showDialog<void>(
                  //                     context: context,
                  //                     builder: (dialogContext) {
                  //                       return AlertWithTwoActions(
                  //                           alertTitle: S.of(context).template,
                  //                           alertContent: S.of(context).confirm_delete_template,
                  //                           leftButtonText: S.of(context).delete,
                  //                           rightButtonText: S.of(context).cancel,
                  //                           actionLeftButton: () {
                  //                             Navigator.of(dialogContext).pop();
                  //                             sendViewModel.sendTemplateStore.remove(template: template);
                  //                             sendViewModel.sendTemplateStore.update();
                  //                           },
                  //                           actionRightButton: () => Navigator.of(dialogContext).pop()
                  //                       );
                  //                     }
                  //                 );
                  //               },
                  //             );
                  //           }
                  //       );
                  //     }
                  // )
                ],
              ),
            ),
          )
        ],
      ),
      bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
      bottomSection: Observer(builder: (_) {
        return LoadingPrimaryButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                print('SENT!!!');
              }
            },
            text: S.of(context).send,
            color: Palette.blueCraiola,
            textColor: Colors.white,
            isLoading: sendViewModel.state is TransactionIsCreating ||
                sendViewModel.state is TransactionCommitting,
            isDisabled:
            false // FIXME !(syncStore.status is SyncedSyncStatus),
        );
      })
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => sendViewModel.sendAll, (bool all) {
      if (all) {
        _cryptoAmountController.text = S.current.all;
        _fiatAmountController.text = null;
      }
    });

    reaction((_) => sendViewModel.fiatAmount, (String amount) {
      if (amount != _fiatAmountController.text) {
        _fiatAmountController.text = amount;
      }
    });

    reaction((_) => sendViewModel.cryptoAmount, (String amount) {
      if (sendViewModel.sendAll && amount != S.current.all) {
        sendViewModel.sendAll = false;
      }

      if (amount != _cryptoAmountController.text) {
        _cryptoAmountController.text = amount;
      }
    });

    reaction((_) => sendViewModel.address, (String address) {
      if (address != _addressController.text) {
        _addressController.text = address;
      }
    });

    _addressController.addListener(() {
      final address = _addressController.text;

      if (sendViewModel.address != address) {
        sendViewModel.address = address;
      }
    });

    reaction((_) => sendViewModel.state, (SendViewModelState state) {
      if (state is SendingFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is TransactionCreatedSuccessfully) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return ConfirmSendingAlert(
                    alertTitle: S.of(context).confirm_sending,
                    amount: S.of(context).send_amount,
                    amountValue:
                    sendViewModel.pendingTransaction.amountFormatted,
                    fee: S.of(context).send_fee,
                    feeValue: sendViewModel.pendingTransaction.feeFormatted,
                    leftButtonText: S.of(context).ok,
                    rightButtonText: S.of(context).cancel,
                    actionLeftButton: () {
                      Navigator.of(context).pop();
                      sendViewModel.commitTransaction();
                      showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Observer(builder: (_) {
                              final state = sendViewModel.state;

                              if (state is TransactionCommitted) {
                                return Stack(
                                  children: <Widget>[
                                    Container(
                                      color: Theme.of(context).backgroundColor,
                                      child: Center(
                                        child: Image.asset(
                                            'assets/images/birthday_cake.png'),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            top: 220, left: 24, right: 24),
                                        child: Text(
                                          S.of(context).send_success,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .title
                                                .color,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        left: 24,
                                        right: 24,
                                        bottom: 24,
                                        child: PrimaryButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            text: S.of(context).send_got_it,
                                            color: Colors.blue,
                                            textColor: Colors.white))
                                  ],
                                );
                              }

                              return Stack(
                                children: <Widget>[
                                  Container(
                                    color: Theme.of(context).backgroundColor,
                                    child: Center(
                                      child: Image.asset(
                                          'assets/images/birthday_cake.png'),
                                    ),
                                  ),
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 3.0, sigmaY: 3.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .backgroundColor
                                              .withOpacity(0.25)),
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 220),
                                          child: Text(
                                            S.of(context).send_sending,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .primaryTextTheme
                                                  .title
                                                  .color,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            });
                          });
                    },
                    actionRightButton: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addressController.text = '';
          _cryptoAmountController.text = '';
        });
      }
    });

    _effectsInstalled = true;
  }

  Future<void> getOpenaliasRecord(BuildContext context) async {
    // final isOpenalias =
    //     await sendViewModel.isOpenaliasRecord(_addressController.text);

    // if (isOpenalias) {
    //   _addressController.text = sendViewModel.recordAddress;

    //   await showDialog<void>(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return AlertWithOneAction(
    //             alertTitle: S.of(context).openalias_alert_title,
    //             alertContent: S
    //                 .of(context)
    //                 .openalias_alert_content(sendViewModel.recordName),
    //             buttonText: S.of(context).ok,
    //             buttonAction: () => Navigator.of(context).pop());
    //       });
    // }
  }

  Future<void> _setTransactionPriority(BuildContext context) async {
    final items = TransactionPriority.all;
    final selectedItem = items.indexOf(sendViewModel.transactionPriority);

    await showDialog<void>(
        builder: (_) => Picker(
          items: items,
          selectedAtIndex: selectedItem,
          title: S.of(context).please_select,
          mainAxisAlignment: MainAxisAlignment.center,
          onItemSelected: (TransactionPriority priority) => null,
          // sendViewModel.setTransactionPriority(priority),
          isAlwaysShowScrollThumb: true,
        ),
        context: context);
  }
}
