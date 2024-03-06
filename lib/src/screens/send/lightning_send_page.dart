import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/lightning_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/generated/i18n.dart';

class LightningSendPage extends BasePage {
  LightningSendPage({
    required this.output,
    required this.authService,
    required this.lightningViewModel,
  }) : _formKey = GlobalKey<FormState>();

  final Output output;
  final AuthService authService;
  final LightningViewModel lightningViewModel;
  final GlobalKey<FormState> _formKey;
  final controller = PageController(initialPage: 0);

  final bolt11Controller = TextEditingController();
  final bolt11FocusNode = FocusNode();

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

  @override
  void onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget trailing(context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
      });

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
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 120, 24, 0),
                child: Column(
                  children: [
                    AddressTextField(
                      focusNode: bolt11FocusNode,
                      controller: bolt11Controller,
                      onURIScanned: (uri) {
                        final paymentRequest = PaymentRequest.fromUri(uri);
                        bolt11Controller.text = paymentRequest.address;
                      },
                      options: [
                        AddressTextFieldOption.paste,
                        AddressTextFieldOption.qrCode,
                        AddressTextFieldOption.addressBook
                      ],
                      buttonColor:
                          Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
                      borderColor:
                          Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor,
                      textStyle:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                      hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor),
                      onPushPasteButton: (context) async {
                        output.resetParsedAddress();
                        await output.fetchParsedAddress(context);
                      },
                      onPushAddressBookButton: (context) async {
                        output.resetParsedAddress();
                      },
                      onSelectedContact: (contact) {
                        output.loadContact(contact);
                      },
                      selectedCurrency: CryptoCurrency.btc,
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Column(
              children: <Widget>[
                LoadingPrimaryButton(
                  text: S.of(context).send,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  isLoading: lightningViewModel.loading,
                  onPressed: () async {
                    try {
                      lightningViewModel.setLoading(true);
                      await processInput(context);
                      lightningViewModel.setLoading(false);
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onNavigateBack(BuildContext context) async {
    onClose(context);
    return false;
  }

  Future<void> processInput(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final sdk = await BreezSDK();

    late InputType inputType;

    try {
      inputType = await sdk.parseInput(input: bolt11Controller.text);
    } catch (_) {
      throw Exception("Unknown input type");
    }

    if (inputType is InputType_Bolt11) {
      final bolt11 = await sdk.parseInvoice(bolt11Controller.text);
      Navigator.of(context).pushNamed(Routes.lightningSendConfirm, arguments: bolt11);
    } else if (inputType is InputType_LnUrlPay) {
      throw Exception("Unsupported input type");
    } else {
      throw Exception("Unknown input type");
    }
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    _effectsInstalled = true;
  }
}
