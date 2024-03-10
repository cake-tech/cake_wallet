import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/anonpay_input_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/anon_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnonPayInvoicePage extends BasePage {
  AnonPayInvoicePage(
    this.anonInvoicePageViewModel,
    this.receiveOptionViewModel,
  ) : _amountFocusNode = FocusNode() {}

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final FocusNode _amountFocusNode;

  final AnonInvoicePageViewModel anonInvoicePageViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final _formKey = GlobalKey<FormState>();

  bool effectsInstalled = false;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  void onClose(BuildContext context) => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget middle(BuildContext context) => PresentReceiveOptionPicker(
      receiveOptionViewModel: receiveOptionViewModel,
      color: titleColor(context));

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
        anonInvoicePageViewModel.reset();
      });

  Future<bool> _onNavigateBack(BuildContext context) async {
    onClose(context);
    return false;
  }

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context));

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
              focusNode: _amountFocusNode,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24),
          content: Container(
            decoration: responsiveLayoutUtil.shouldRenderMobileUI ? BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).extension<ExchangePageTheme>()!.firstGradientTopPanelColor,
                  Theme.of(context).extension<ExchangePageTheme>()!.secondGradientTopPanelColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              ) : null,
              child: Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, 120, 24, 0),
                  child: AnonInvoiceForm(
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    amountController: _amountController,
                    emailController: _emailController,
                    depositAmountFocus: _amountFocusNode,
                    formKey: _formKey,
                    isInvoice: receiveOptionViewModel.selectedReceiveOption ==
                        ReceivePageOption.anonPayInvoice,
                    anonInvoicePageViewModel: anonInvoicePageViewModel,
                  ),
                );
              }),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
              final isInvoice =
                  receiveOptionViewModel.selectedReceiveOption == ReceivePageOption.anonPayInvoice;
              return Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Center(
                      child: Text(
                        isInvoice
                            ? S.of(context).anonpay_description("an invoice", "pay")
                            : S.of(context).anonpay_description("a donation link", "donate"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).extension<ExchangePageTheme>()!.receiveAmountColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12),
                      ),
                    ),
                  ),
                  LoadingPrimaryButton(
                    text: isInvoice
                        ? S.of(context).create_invoice
                        : S.of(context).create_donation_link,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      anonInvoicePageViewModel.setRequestParams(
                        inputAmount: _amountController.text,
                        inputName: _nameController.text,
                        inputEmail: _emailController.text,
                        inputDescription: _descriptionController.text,
                      );
                      if (anonInvoicePageViewModel.receipientEmail.isNotEmpty &&
                          _formKey.currentState != null &&
                          !_formKey.currentState!.validate()) {
                        return;
                      }
                      if (isInvoice) {
                        anonInvoicePageViewModel.createInvoice();
                      } else {
                        anonInvoicePageViewModel.generateDonationLink();
                      }
                    },
                     color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isLoading: anonInvoicePageViewModel.state is IsExecutingState,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _setReactions(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) {
      switch (option) {
        case ReceivePageOption.mainnet:
          Navigator.popAndPushNamed(context, Routes.addressPage);
          break;
        case ReceivePageOption.anonPayDonationLink:
          final sharedPreferences = getIt.get<SharedPreferences>();
          final clearnetUrl = sharedPreferences.getString(PreferencesKey.clearnetDonationLink);
          final onionUrl = sharedPreferences.getString(PreferencesKey.onionDonationLink);

          if (clearnetUrl != null && onionUrl != null) {
            Navigator.pushReplacementNamed(context, Routes.anonPayReceivePage,
                arguments: AnonpayDonationLinkInfo(
                  clearnetUrl: clearnetUrl,
                  onionUrl: onionUrl,
                  address: anonInvoicePageViewModel.address,
                ));
          }
          break;
        default:
      }
    });

    reaction((_) => anonInvoicePageViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        Navigator.pushNamed(context, Routes.anonPayReceivePage, arguments: state.payload);
      }
      if (state is FailureState) {
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).error,
                  alertContent: state.error.toString(),
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
      }
    });

    effectsInstalled = true;
  }
}
