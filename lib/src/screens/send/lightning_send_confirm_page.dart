import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/generated/i18n.dart';

class LightningSendConfirmPage extends BasePage {
  LightningSendConfirmPage({required this.invoice}) : _formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _formKey;
  final controller = PageController(initialPage: 0);
  LNInvoice invoice;

  final bolt11Controller = TextEditingController();
  final _bolt11FocusNode = FocusNode();

  bool _effectsInstalled = false;

  @override
  String get title => S.current.send;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  Widget? leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: titleColor(context),
      size: 16,
    );
    final _closeButton =
        currentTheme.type == ThemeType.dark ? closeButtonImageDarkTheme : closeButtonImage;

    bool isMobileView = responsiveLayoutUtil.shouldRenderMobileUI;

    return MergeSemantics(
      child: SizedBox(
        height: isMobileView ? 37 : 45,
        width: isMobileView ? 37 : 45,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: !isMobileView ? S.of(context).close : S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
              ),
              onPressed: () => onClose(context),
              child: !isMobileView ? _closeButton : _backButton,
            ),
          ),
        ),
      ),
    );
  }

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  double _sendCardHeight(BuildContext context) {
    final double initialHeight = 465;

    if (!responsiveLayoutUtil.shouldRenderMobileUI) {
      return initialHeight - 66;
    }
    return initialHeight;
  }

  @override
  void onClose(BuildContext context) {
    // sendViewModel.onClose();
    Navigator.of(context).pop();
  }

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return WillPopScope(
      onWillPop: () => _onNavigateBack(context),
      child: KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: FocusNode(),
                // focusNode: _amountFocusNode,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              ),
            ]),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Container(
              decoration: responsiveLayoutUtil.shouldRenderMobileUI
                  ? BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .firstGradientTopPanelColor,
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .secondGradientTopPanelColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, 120, 24, 0),
                  child: Column(
                    children: [
                      BaseTextFormField(
                        enabled: false,
                        borderColor: Theme.of(context)
                            .extension<ExchangePageTheme>()!
                            .textFieldBorderTopPanelColor,
                        suffixIcon: SizedBox(width: 36),
                        initialValue: "${S.of(context).invoice}: ${invoice.bolt11}",
                        placeholderTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        validator: null,
                      ),
                      SizedBox(height: 24),
                      BaseTextFormField(
                        enabled: false,
                        borderColor: Theme.of(context)
                            .extension<ExchangePageTheme>()!
                            .textFieldBorderTopPanelColor,
                        suffixIcon: SizedBox(width: 36),
                        initialValue:
                            "sats: ${bitcoinAmountToLightningString(amount: (invoice.amountMsat ?? 0) ~/ 1000)}",
                        placeholderTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        validator: null,
                      ),
                      SizedBox(height: 24),
                      BaseTextFormField(
                        enabled: false,
                        initialValue: "USD: ${invoice.amountMsat}",
                        borderColor: Theme.of(context)
                            .extension<ExchangePageTheme>()!
                            .textFieldBorderTopPanelColor,
                        suffixIcon: SizedBox(width: 36),
                        placeholderTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                        ),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        validator: null,
                      ),
                      SizedBox(height: 24),
                      if (invoice.description?.isNotEmpty ?? false) ...[
                        BaseTextFormField(
                          enabled: false,
                          initialValue: "${S.of(context).description}: ${invoice.description}",
                          textInputAction: TextInputAction.next,
                          borderColor: Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .textFieldBorderTopPanelColor,
                          suffixIcon: SizedBox(width: 36),
                          placeholderTextStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                          ),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          validator: null,
                        ),
                        SizedBox(height: 24),
                      ],
                    ],
                  ),
                );
              }),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
              return Column(
                children: <Widget>[
                  LoadingPrimaryButton(
                    text: S.of(context).send,
                    onPressed: () async {
                      try {
                        final sdk = await BreezSDK();
                        await sdk.sendPayment(req: SendPaymentRequest(bolt11: invoice.bolt11));
                        showPopUp<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithOneAction(
                                  alertTitle: '',
                                  alertContent: S
                                      .of(context)
                                      .send_success(CryptoCurrency.btc.toString()),
                                  buttonText: S.of(context).ok,
                                  buttonAction: () {
                                    Navigator.of(context).pop();
                                  });
                            });
                      } catch (e) {
                        showPopUp<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithOneAction(
                                  alertTitle: S.of(context).error,
                                  alertContent: e.toString(),
                                  buttonText: S.of(context).ok,
                                  buttonAction: () => Navigator.of(context).pop());
                            });
                      }
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isLoading: false,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<bool> _onNavigateBack(BuildContext context) async {
    onClose(context);
    return false;
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    _effectsInstalled = true;
  }
}
