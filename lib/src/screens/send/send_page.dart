import 'dart:ui';
import 'package:cake_wallet/src/screens/send/widgets/parse_address_from_domain_alert.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SendPage extends BasePage {
  SendPage({@required this.sendViewModel}) :_formKey = GlobalKey<FormState>();

  final SendViewModel sendViewModel;
  final GlobalKey<FormState> _formKey;
  final controller = PageController(initialPage: 0);

  bool _effectsInstalled = false;

  @override
  String get title => S.current.send;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(context) => Observer(builder: (_) {
    return sendViewModel.isBatchSending
        ? TrailButton(
        caption: S.of(context).remove,
        onPressed: () {
          var pageToJump = controller.page.round() - 1;
          pageToJump = pageToJump > 0 ? pageToJump : 0;
          final output = _defineCurrentOutput();
          sendViewModel.removeOutput(output);
          controller.jumpToPage(pageToJump);
        })
        : TrailButton(
        caption: S.of(context).clear,
        onPressed: () {
          final output = _defineCurrentOutput();
          _formKey.currentState.reset();
          output.reset();
        });
  });

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return Form(
      key: _formKey,
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24),
          content: Column(
            children: <Widget>[
              Container(
                  height: sendViewModel.isElectrumWallet ? 490 : 465,
                  child: Observer(
                    builder: (_) {
                      return PageView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: controller,
                          itemCount: sendViewModel.outputs.length,
                          itemBuilder: (context, index) {
                            final output = sendViewModel.outputs[index];

                            return SendCard(
                              key: output.key,
                              output: output,
                              sendViewModel: sendViewModel,
                            );
                          }
                      );
                    },
                  )
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 10),
                  child: Container(
                      height: 10,
                      child: Observer(builder: (_) {
                        final count = sendViewModel.outputs.length;

                        return count > 1
                          ? SmoothPageIndicator(
                            controller: controller,
                            count: count,
                            effect: ScrollingDotsEffect(
                                spacing: 6.0,
                                radius: 6.0,
                                dotWidth: 6.0,
                                dotHeight: 6.0,
                                dotColor: Theme.of(context)
                                    .primaryTextTheme
                                    .display2
                                    .backgroundColor,
                                activeDotColor: Theme.of(context)
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
                                validator: sendViewModel.addressValidator,
                                onPushPasteButton: (context) {
                                  applyOpenaliasOrUnstoppableDomains(context);
                                },
                              ),
                              Observer(
                                  builder: (_) => Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Stack(
                                        children: [
                                          BaseTextFormField(
                                            focusNode: _cryptoAmountFocus,
                                            controller: _cryptoAmountController,
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
                                            validator: sendViewModel.sendAll
                                              ? sendViewModel.allAmountValidator
                                              : sendViewModel
                                              .amountValidator),
                                          Positioned(
                                            top: 2,
                                            right: 0,
                                            child: Container(
                                              width: prefixIconWidth,
                                              height: prefixIconHeight,
                                              child: InkWell(
                                                onTap: () async =>
                                                    sendViewModel.setSendAll(),
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
                                    focusNode: _fiatAmountFocus,
                                    controller: _fiatAmountController,
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
                                    controller: _noteController,
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
                                                            sendViewModel
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
                                                            sendViewModel
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
                                  .display2
                                  .decorationColor,
                              strokeWidth: 2,
                              radius: Radius.circular(20),
                              child: Container(
                                height: 34,
                                width: 75,
                                padding:
                                EdgeInsets.only(left: 10, right: 10),
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
                      Observer(builder: (_) {
                        final templates = sendViewModel.templates;
                        final itemCount = templates.length;

                        return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              final template = templates[index];

                              return TemplateTile(
                                key: UniqueKey(),
                                to: template.name,
                                amount: template.amount,
                                from: template.cryptoCurrency,
                                onTap: () async {
                                  final output = _defineCurrentOutput();
                                  output.address =
                                      template.address;
                                  output.setCryptoAmount(template.amount);
                                  final parsedAddress = await output
                                      .applyOpenaliasOrUnstoppableDomains();
                                  showAddressAlert(context, parsedAddress);
                                },
                                onRemove: () {
                                  showPopUp<void>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertWithTwoActions(
                                            alertTitle:
                                            S.of(context).template,
                                            alertContent: S
                                                .of(context)
                                                .confirm_delete_template,
                                            rightButtonText:
                                            S.of(context).delete,
                                            leftButtonText:
                                            S.of(context).cancel,
                                            actionRightButton: () {
                                              Navigator.of(dialogContext)
                                                  .pop();
                                              sendViewModel
                                                  .sendTemplateViewModel
                                                  .removeTemplate(
                                                  template: template);
                                            },
                                            actionLeftButton: () =>
                                                Navigator.of(dialogContext)
                                                    .pop());
                                      });
                                },
                              );
                            });
                      })
                    ],
                  ),
                ),
              )
            ],
          ),
          bottomSectionPadding:
          EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: PrimaryButton(
                  onPressed: () {
                    sendViewModel.addOutput();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      controller.jumpToPage(sendViewModel.outputs.length - 1);
                    });
                  },
                  text: S.of(context).add_receiver,
                  color: Colors.transparent,
                  textColor: Theme.of(context)
                      .accentTextTheme
                      .display2
                      .decorationColor,
                  isDottedBorder: true,
                  borderColor: Theme.of(context)
                      .primaryTextTheme
                      .display2
                      .decorationColor,
                )
              ),
              Observer(builder: (_) {
                return LoadingPrimaryButton(
                  onPressed: () async {
                    if (!_formKey.currentState.validate()) {
                      if (sendViewModel.outputs.length > 1) {
                        showErrorValidationAlert(context);
                      }

                      return;
                    }

                    final notValidItems = sendViewModel.outputs
                        .where((item) =>
                        item.address.isEmpty || item.cryptoAmount.isEmpty)
                        .toList();

                    if (notValidItems?.isNotEmpty ?? false) {
                      showErrorValidationAlert(context);
                      return;
                    }

                    await sendViewModel.createTransaction();
                  },
                  text: S.of(context).send,
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
                  isLoading: sendViewModel.state is IsExecutingState ||
                      sendViewModel.state is TransactionCommitting,
                  isDisabled: !sendViewModel.isReadyForSend,
                );
              },
              )
            ],
          )),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => sendViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
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

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return ConfirmSendingAlert(
                    alertTitle: S.of(context).confirm_sending,
                    amount: S.of(context).send_amount,
                    amountValue:
                    sendViewModel.pendingTransaction.amountFormatted,
                    fiatAmountValue: sendViewModel.pendingTransactionFiatAmount
                        +  ' ' + sendViewModel.fiat.title,
                    fee: S.of(context).send_fee,
                    feeValue: sendViewModel.pendingTransaction.feeFormatted,
                    feeFiatAmount: sendViewModel.pendingTransactionFeeFiatAmount
                        +  ' ' + sendViewModel.fiat.title,
                    outputs: sendViewModel.outputs,
                    rightButtonText: S.of(context).ok,
                    leftButtonText: S.of(context).cancel,
                    actionRightButton: () {
                      Navigator.of(context).pop();
                      sendViewModel.commitTransaction();
                      showPopUp<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Observer(builder: (_) {
                              final state = sendViewModel.state;

                              if (state is FailureState) {
                                Navigator.of(context).pop();
                              }

                              if (state is TransactionCommitted) {
                                return AlertWithOneAction(
                                    alertTitle: '',
                                    alertContent: S.of(context).send_success(
                                        sendViewModel.currency
                                            .toString()),
                                    buttonText: S.of(context).ok,
                                    buttonAction: () =>
                                        Navigator.of(context).pop());
                              }

                              return Offstage();
                            });
                          });
                    },
                    actionLeftButton: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sendViewModel.clearOutputs();
        });
      }
    });

    _effectsInstalled = true;
  }

  Output _defineCurrentOutput() {
    final itemCount = controller.page.round();
    return sendViewModel.outputs[itemCount];
  }

  void showErrorValidationAlert(BuildContext context) async {
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.of(context).error,
              alertContent: 'Please, check receiver forms',
              buttonText: S.of(context).ok,
              buttonAction: () =>
                  Navigator.of(context).pop());
        });
  }
}
