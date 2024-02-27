import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/src/screens/receive/widgets/lightning_input_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/lightning_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/lightning_view_model.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_lightning/lightning_receive_page_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';

class LightningInvoicePage extends BasePage {
  LightningInvoicePage({
    required this.lightningViewModel,
    required this.lightningInvoicePageViewModel,
    required this.receiveOptionViewModel,
  }) : _amountFocusNode = FocusNode() {}

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final FocusNode _amountFocusNode;

  final LightningViewModel lightningViewModel;
  final LightningInvoicePageViewModel lightningInvoicePageViewModel;
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
      receiveOptionViewModel: receiveOptionViewModel, color: titleColor(context));

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
        // lightningViewModel.reset();
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
                  child: LightningInvoiceForm(
                    descriptionController: _descriptionController,
                    amountController: _amountController,
                    depositAmountFocus: _amountFocusNode,
                    formKey: _formKey,
                    lightningInvoicePageViewModel: lightningInvoicePageViewModel,
                  ),
                );
              }),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
              return Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(top: 12, bottom: 12, right: 6),
                    margin: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                      color: Color.fromARGB(94, 255, 221, 44),
                      border: Border.all(
                        color: Color.fromARGB(178, 223, 214, 0),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          margin: EdgeInsets.only(left: 12, bottom: 48, right: 12),
                          child: Image.asset("assets/images/warning.png"),
                        ),
                        FutureBuilder(
                          future: lightningInvoicePageViewModel.lightningViewModel.invoiceLimitsSats(),
                          builder: (context, snapshot) {
                            if (snapshot.data == null) {
                              return SizedBox();
                            }
                            String min = (snapshot.data as List<String>)[0];
                            min = satsToLightningString(double.parse(min));
                            return Expanded(
                              child: Text(
                                // S.of(context).lightning_invoice_min(min)
                                "Needs fixing!: $min",
                                maxLines: 3,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  LoadingPrimaryButton(
                    text: S.of(context).create_invoice,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      lightningInvoicePageViewModel.setRequestParams(
                        inputAmount: _amountController.text,
                        inputDescription: _descriptionController.text,
                      );
                      lightningInvoicePageViewModel.createInvoice();
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isLoading: lightningInvoicePageViewModel.state is IsExecutingState,
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

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) async {
      switch (option) {
        case LightningReceivePageOption.lightningInvoice:
          break;
        case LightningReceivePageOption.lightningOnchain:
          Navigator.popAndPushNamed(
            context,
            Routes.lightningReceiveOnchain,
            arguments: [LightningReceivePageOption.lightningOnchain],
          );
          break;
        default:
          break;
      }
    });

    reaction((_) => lightningInvoicePageViewModel.state, (ExecutionState state) {

      if (state is ExecutedSuccessfullyState) {
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                alertTitle: S.of(context).invoice_created,
                alertContent: state.payload as String,
                rightButtonText: S.of(context).ok,
                actionRightButton: () => Navigator.of(context).pop(),
                actionLeftButton: () async {
                  Clipboard.setData(ClipboardData(text: state.payload as String));
                  showBar<void>(context, S.of(context).copied_to_clipboard);
                },
                leftButtonText: S.of(context).copy,
              );
            });
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
