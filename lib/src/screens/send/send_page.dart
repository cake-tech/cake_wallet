import 'dart:ui';
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
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/base_send_widget.dart';

// FIXME: Refactor this screen.

class SendPage extends BasePage {
  SendPage({@required this.sendViewModel});

  final SendViewModel sendViewModel;

  // ???
  @override
  String get title => 'SEND';

  @override
  Color get titleColor => Colors.white;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget trailing(context) => TrailButton(
      caption: S.of(context).clear, onPressed: () => sendViewModel.reset());
  Color get backgroundDarkColor => Colors.transparent;

  // @override
  // State<StatefulWidget> createState() => SendFormState();

  final _addressController = TextEditingController();
  final _cryptoAmountController = TextEditingController();
  final _fiatAmountController = TextEditingController();

  final _focusNode = FocusNode();

  bool _effectsInstalled = false;

  final _formKey = GlobalKey<FormState>();

  // @override
  // void initState() {
  //   _focusNode.addListener(() {
  //     if (!_focusNode.hasFocus && _addressController.text.isNotEmpty) {
  //       getOpenaliasRecord(context);
  //     }
  //   });

  //   super.initState();
  // }

  Future<void> getOpenaliasRecord(BuildContext context) async {
//    final sendStore = Provider.of<SendStore>(context);
//    final isOpenalias =
//        await sendStore.isOpenaliasRecord(_addressController.text);
//
//    if (isOpenalias) {
//      _addressController.text = sendStore.recordAddress;
//
//      await showDialog<void>(
//          context: context,
//          builder: (BuildContext context) {
//            return AlertWithOneAction(
//                alertTitle: S.of(context).openalias_alert_title,
//                alertContent:
//                    S.of(context).openalias_alert_content(sendStore.recordName),
//                buttonText: S.of(context).ok,
//                buttonAction: () => Navigator.of(context).pop());
//          });
//    }
  }

  // @override
  // Widget body(BuildContext context) {
  //   return super.build(context);
  // }

  @override
  Widget body(BuildContext context) => BaseSendWidget(
        sendViewModel: sendViewModel,
        leading: leading(context),
        middle: middle(context),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
        body: Container(
            color: Theme.of(context).backgroundColor, child: body(context)));
  }

//   @override
//   Widget build(BuildContext context) {
//     _setEffects(context);

//     return Container(
//       color: Theme.of(context).backgroundColor,
//       child: ScrollableWithBottomSection(
//         contentPadding: EdgeInsets.only(bottom: 24),
//         content: Column(
//           children: <Widget>[
//             TopPanel(
//               color: Theme.of(context).accentTextTheme.title.backgroundColor,
//               widget: Form(
//                 key: _formKey,
//                 child: Column(children: <Widget>[
//                   AddressTextField(
//                     controller: _addressController,
//                     placeholder: 'Address',
//                     //S.of(context).send_monero_address, FIXME: placeholder for btc and xmr address text field.
//                     focusNode: _focusNode,
//                     onURIScanned: (uri) {
//                       var address = '';
//                       var amount = '';

//                       if (uri != null) {
//                         address = uri.path;
//                         amount = uri.queryParameters['tx_amount'];
//                       } else {
//                         address = uri.toString();
//                       }

//                       _addressController.text = address;
//                       _cryptoAmountController.text = amount;
//                     },
//                     options: [
//                       AddressTextFieldOption.qrCode,
//                       AddressTextFieldOption.addressBook
//                     ],
//                     buttonColor: Theme.of(context).accentTextTheme.title.color,
//                     validator: widget.sendViewModel.addressValidator,
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 20),
//                     child: TextFormField(
//                         onChanged: (value) =>
//                             widget.sendViewModel.setCryptoAmount(value),
//                         style: TextStyle(
//                             fontSize: 16.0,
//                             color:
//                                 Theme.of(context).primaryTextTheme.title.color),
//                         controller: _cryptoAmountController,
//                         keyboardType: TextInputType.numberWithOptions(
//                             signed: false, decimal: true),
// //                          inputFormatters: [
// //                            BlacklistingTextInputFormatter(
// //                                RegExp('[\\-|\\ |\\,]'))
// //                          ],
//                         decoration: InputDecoration(
//                             prefixIcon: Padding(
//                               padding: EdgeInsets.only(top: 12),
//                               child: Text(
//                                   '${widget.sendViewModel.currency.toString()}:',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Theme.of(context)
//                                         .primaryTextTheme
//                                         .title
//                                         .color,
//                                   )),
//                             ),
//                             suffixIcon: Padding(
//                                 padding: EdgeInsets.only(bottom: 5),
//                                 child: Container(
//                                   height: 32,
//                                   width: 32,
//                                   margin: EdgeInsets.only(
//                                       left: 12, bottom: 7, top: 4),
//                                   decoration: BoxDecoration(
//                                       color: Theme.of(context)
//                                           .accentTextTheme
//                                           .title
//                                           .color,
//                                       borderRadius:
//                                           BorderRadius.all(Radius.circular(6))),
//                                   child: InkWell(
//                                     onTap: () => widget.sendViewModel.setAll(),
//                                     child: Center(
//                                       child: Text(S.of(context).all,
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                               fontSize: 9,
//                                               fontWeight: FontWeight.bold,
//                                               color: Theme.of(context)
//                                                   .primaryTextTheme
//                                                   .caption
//                                                   .color)),
//                                     ),
//                                   ),
//                                 )),
//                             hintStyle: TextStyle(
//                                 fontSize: 16.0,
//                                 color: Theme.of(context)
//                                     .primaryTextTheme
//                                     .title
//                                     .color),
//                             hintText: '0.0000',
//                             focusedBorder: UnderlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: Theme.of(context).dividerColor,
//                                     width: 1.0)),
//                             enabledBorder: UnderlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: Theme.of(context).dividerColor,
//                                     width: 1.0))),
//                         validator: (String value) {
//                           if (widget.sendViewModel.all) {
//                             return null;
//                           }

//                           return widget.sendViewModel.amountValidator
//                               .call(value);
//                         }),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 20),
//                     child: TextFormField(
//                         onChanged: (value) =>
//                             widget.sendViewModel.setFiatAmount(value),
//                         style: TextStyle(
//                             fontSize: 16.0,
//                             color:
//                                 Theme.of(context).primaryTextTheme.title.color),
//                         controller: _fiatAmountController,
//                         keyboardType: TextInputType.numberWithOptions(
//                             signed: false, decimal: true),
// //                        inputFormatters: [
// //                          BlacklistingTextInputFormatter(
// //                              RegExp('[\\-|\\ |\\,]'))
// //                        ],
//                         decoration: InputDecoration(
//                             prefixIcon: Padding(
//                               padding: EdgeInsets.only(top: 12),
//                               child: Text(
//                                   '${widget.sendViewModel.fiat.toString()}:',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Theme.of(context)
//                                         .primaryTextTheme
//                                         .title
//                                         .color,
//                                   )),
//                             ),
//                             hintStyle: TextStyle(
//                                 fontSize: 16.0,
//                                 color: Theme.of(context)
//                                     .primaryTextTheme
//                                     .caption
//                                     .color),
//                             hintText: '0.00',
//                             focusedBorder: UnderlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: Theme.of(context).dividerColor,
//                                     width: 1.0)),
//                             enabledBorder: UnderlineInputBorder(
//                                 borderSide: BorderSide(
//                                     color: Theme.of(context).dividerColor,
//                                     width: 1.0)))),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(top: 20),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: <Widget>[
//                         Text(S.of(context).send_estimated_fee,
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Theme.of(context)
//                                   .primaryTextTheme
//                                   .title
//                                   .color,
//                             )),
//                         Text(
//                             '${widget.sendViewModel.estimatedFee} ${widget.sendViewModel.currency.toString()}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Theme.of(context)
//                                   .primaryTextTheme
//                                   .title
//                                   .color,
//                             ))
//                       ],
//                     ),
//                   )
//                 ]),
//               ),
//             ),
// //            Padding(
// //              padding: EdgeInsets.only(top: 32, left: 24, bottom: 24),
// //              child: Row(
// //                mainAxisAlignment: MainAxisAlignment.start,
// //                children: <Widget>[
// //                  Text(
// //                    S.of(context).send_templates,
// //                    style: TextStyle(
// //                        fontSize: 18,
// //                        fontWeight: FontWeight.w600,
// //                        color:
// //                            Theme.of(context).primaryTextTheme.caption.color),
// //                  )
// //                ],
// //              ),
// //            ),
// //            Container(
// //              height: 40,
// //              width: double.infinity,
// //              padding: EdgeInsets.only(left: 24),
// //              child: Observer(builder: (_) {
// //                final itemCount = sendTemplateStore.templates.length + 1;
// //
// //                return ListView.builder(
// //                    scrollDirection: Axis.horizontal,
// //                    itemCount: itemCount,
// //                    itemBuilder: (context, index) {
// //                      if (index == 0) {
// //                        return GestureDetector(
// //                          onTap: () => Navigator.of(context)
// //                              .pushNamed(Routes.sendTemplate),
// //                          child: Container(
// //                            padding: EdgeInsets.only(right: 10),
// //                            child: DottedBorder(
// //                                borderType: BorderType.RRect,
// //                                dashPattern: [8, 4],
// //                                color: Theme.of(context)
// //                                    .accentTextTheme
// //                                    .title
// //                                    .backgroundColor,
// //                                strokeWidth: 2,
// //                                radius: Radius.circular(20),
// //                                child: Container(
// //                                  height: 40,
// //                                  width: 75,
// //                                  padding: EdgeInsets.only(left: 10, right: 10),
// //                                  alignment: Alignment.center,
// //                                  decoration: BoxDecoration(
// //                                    borderRadius:
// //                                        BorderRadius.all(Radius.circular(20)),
// //                                    color: Colors.transparent,
// //                                  ),
// //                                  child: Text(
// //                                    S.of(context).send_new,
// //                                    style: TextStyle(
// //                                        fontSize: 14,
// //                                        fontWeight: FontWeight.w600,
// //                                        color: Theme.of(context)
// //                                            .primaryTextTheme
// //                                            .caption
// //                                            .color),
// //                                  ),
// //                                )),
// //                          ),
// //                        );
// //                      }
// //
// //                      index -= 1;
// //
// //                      final template = sendTemplateStore.templates[index];
// //
// //                      return TemplateTile(
// //                          to: template.name,
// //                          amount: template.amount,
// //                          from: template.cryptoCurrency,
// //                          onTap: () {
// //                            _addressController.text = template.address;
// //                            _cryptoAmountController.text = template.amount;
// //                            getOpenaliasRecord(context);
// //                          });
// //                    });
// //              }),
// //            )
//           ],
//         ),
//         bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
//         bottomSection: Observer(builder: (_) {
//           return LoadingPrimaryButton(
//               onPressed: () async {
//                 FocusScope.of(context).requestFocus(FocusNode());

//                 if (!_formKey.currentState.validate()) {
//                   return;
//                 }

//                 await showDialog<void>(
//                     context: context,
//                     builder: (dialogContext) {
//                       return AlertWithTwoActions(
//                           alertTitle: S.of(context).send_creating_transaction,
//                           alertContent: S.of(context).confirm_sending,
//                           leftButtonText: S.of(context).send,
//                           rightButtonText: S.of(context).cancel,
//                           actionLeftButton: () async {
//                             await Navigator.of(dialogContext)
//                                 .popAndPushNamed(Routes.auth, arguments:
//                                     (bool isAuthenticatedSuccessfully,
//                                         AuthPageState auth) {
//                               if (!isAuthenticatedSuccessfully) {
//                                 return;
//                               }

//                               Navigator.of(auth.context).pop();
//                               widget.sendViewModel.createTransaction();
//                             });
//                           },
//                           actionRightButton: () => Navigator.of(context).pop());
//                     });
//               },
//               text: S.of(context).send,
//               color: Colors.blue,
//               textColor: Colors.white,
//               isLoading: widget.sendViewModel.state is TransactionIsCreating ||
//                   widget.sendViewModel.state is TransactionCommitting,
//               isDisabled: !widget.sendViewModel.isReadyForSend);
//         }),
//       ),
//     );
//   }

//   void _setEffects(BuildContext context) {
//     if (_effectsInstalled) {
//       return;
//     }

//     reaction((_) => widget.sendViewModel.all, (bool all) {
//       if (all) {
//         _cryptoAmountController.text = S.current.all;
//         _fiatAmountController.text = null;
//       }
//     });

//     reaction((_) => widget.sendViewModel.fiatAmount, (String amount) {
//       if (amount != _fiatAmountController.text) {
//         _fiatAmountController.text = amount;
//       }
//     });

//     reaction((_) => widget.sendViewModel.cryptoAmount, (String amount) {
//       if (widget.sendViewModel.all && amount != S.current.all) {
//         widget.sendViewModel.all = false;
//       }

//       if (amount != _cryptoAmountController.text) {
//         _cryptoAmountController.text = amount;
//       }
//     });

//     reaction((_) => widget.sendViewModel.address, (String address) {
//       if (address != _addressController.text) {
//         _addressController.text = address;
//       }
//     });

//     _addressController.addListener(() {
//       final address = _addressController.text;

//       if (widget.sendViewModel.address != address) {
//         widget.sendViewModel.address = address;
//       }
//     });

//     reaction((_) => widget.sendViewModel.state, (SendViewModelState state) {
//       if (state is SendingFailed) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           showDialog<void>(
//               context: context,
//               builder: (BuildContext context) {
//                 return AlertWithOneAction(
//                     alertTitle: S.of(context).error,
//                     alertContent: state.error,
//                     buttonText: S.of(context).ok,
//                     buttonAction: () => Navigator.of(context).pop());
//               });
//         });
//       }

//       if (state is TransactionCreatedSuccessfully) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           showDialog<void>(
//               context: context,
//               builder: (BuildContext context) {
//                 return ConfirmSendingAlert(
//                     alertTitle: S.of(context).confirm_sending,
//                     amount: S.of(context).send_amount,
//                     amountValue:
//                         widget.sendViewModel.pendingTransaction.amountFormatted,
//                     fee: S.of(context).send_fee,
//                     feeValue:
//                         widget.sendViewModel.pendingTransaction.feeFormatted,
//                     leftButtonText: S.of(context).ok,
//                     rightButtonText: S.of(context).cancel,
//                     actionLeftButton: () {
//                       Navigator.of(context).pop();
//                       widget.sendViewModel.commitTransaction();
//                       showDialog<void>(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return Observer(builder: (_) {
//                               final state = widget.sendViewModel.state;

//                               if (state is TransactionCommitted) {
//                                 return Stack(
//                                   children: <Widget>[
//                                     Container(
//                                       color: Theme.of(context).backgroundColor,
//                                       child: Center(
//                                         child: Image.asset(
//                                             'assets/images/birthday_cake.png'),
//                                       ),
//                                     ),
//                                     Center(
//                                       child: Padding(
//                                         padding: EdgeInsets.only(
//                                             top: 220, left: 24, right: 24),
//                                         child: Text(
//                                           S.of(context).send_success,
//                                           textAlign: TextAlign.center,
//                                           style: TextStyle(
//                                             fontSize: 22,
//                                             fontWeight: FontWeight.bold,
//                                             color: Theme.of(context)
//                                                 .primaryTextTheme
//                                                 .title
//                                                 .color,
//                                             decoration: TextDecoration.none,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     Positioned(
//                                         left: 24,
//                                         right: 24,
//                                         bottom: 24,
//                                         child: PrimaryButton(
//                                             onPressed: () =>
//                                                 Navigator.of(context).pop(),
//                                             text: S.of(context).send_got_it,
//                                             color: Colors.blue,
//                                             textColor: Colors.white))
//                                   ],
//                                 );
//                               }

//                               return Stack(
//                                 children: <Widget>[
//                                   Container(
//                                     color: Theme.of(context).backgroundColor,
//                                     child: Center(
//                                       child: Image.asset(
//                                           'assets/images/birthday_cake.png'),
//                                     ),
//                                   ),
//                                   BackdropFilter(
//                                     filter: ImageFilter.blur(
//                                         sigmaX: 3.0, sigmaY: 3.0),
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                           color: Theme.of(context)
//                                               .backgroundColor
//                                               .withOpacity(0.25)),
//                                       child: Center(
//                                         child: Padding(
//                                           padding: EdgeInsets.only(top: 220),
//                                           child: Text(
//                                             S.of(context).send_sending,
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                               fontSize: 22,
//                                               fontWeight: FontWeight.bold,
//                                               color: Theme.of(context)
//                                                   .primaryTextTheme
//                                                   .title
//                                                   .color,
//                                               decoration: TextDecoration.none,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   )
//                                 ],
//                               );
//                             });
//                           });
//                     },
//                     actionRightButton: () => Navigator.of(context).pop());
//               });
//         });
//       }

//       if (state is TransactionCommitted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _addressController.text = '';
//           _cryptoAmountController.text = '';
//         });
//       }
//     });

//     _effectsInstalled = true;
//   }

//   Widget body(BuildContext context) => BaseSendWidget(
//         sendViewModel: sendViewModel,
//         leading: leading(context),
//         middle: middle(context),
//       );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         resizeToAvoidBottomPadding: resizeToAvoidBottomPadding,
//         body: Container(
//             color: Theme.of(context).backgroundColor, child: body(context)));
//   }
}
