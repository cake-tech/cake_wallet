import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';

class AddressPage extends BasePage {
  AddressPage({
    required this.addressListViewModel,
    required this.dashboardViewModel,
    required this.receiveOptionViewModel,
  })  : _cryptoAmountFocus = FocusNode(),
        _formKey = GlobalKey<FormState>(),
        _amountController = TextEditingController() {
    _amountController.addListener(() {
      if (_formKey.currentState!.validate()) {
        addressListViewModel.changeAmount(
          _amountController.text,
        );
      }
    });
  }

  final WalletAddressListViewModel addressListViewModel;
  final DashboardViewModel dashboardViewModel;
  final ReceiveOptionViewModel receiveOptionViewModel;
  final TextEditingController _amountController;
  final GlobalKey<FormState> _formKey;

  final FocusNode _cryptoAmountFocus;

  @override
  bool get gradientBackground => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  bool effectsInstalled = false;

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
  Widget middle(BuildContext context) => PresentReceiveOptionPicker(
      color: titleColor(context), receiveOptionViewModel: receiveOptionViewModel);

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  Widget? trailing(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        label: S.of(context).share,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          iconSize: 25,
          onPressed: () {
            ShareUtil.share(
              text: addressListViewModel.uri.toString(),
              context: context,
            );
          },
          icon: Icon(Icons.share, size: 20, color: pageIconColor(context)),
        ),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return KeyboardActions(
        autoScroll: false,
        disableScroll: true,
        tapOutsideBehavior: TapOutsideBehavior.translucentDismiss,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _cryptoAmountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              )
            ]),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: Observer(
                      builder: (_) => QRWidget(
                          formKey: _formKey,
                          addressListViewModel: addressListViewModel,
                          amountTextFieldFocusNode: _cryptoAmountFocus,
                          amountController: _amountController,
                          isLight: dashboardViewModel.settingsStore.currentTheme.type ==
                              ThemeType.light))),
              SizedBox(height: 16),
              Observer(builder: (_) {
                if (addressListViewModel.hasAddressList) {
                  return SelectButton(
                    text: addressListViewModel.buttonTitle,
                    onTap: () async => dashboardViewModel.isAutoGenerateSubaddressesEnabled &&
                            (WalletType.monero == addressListViewModel.wallet.type ||
                                WalletType.haven == addressListViewModel.wallet.type)
                        ? await showPopUp<void>(
                            context: context, builder: (_) => getIt.get<MoneroAccountListPage>())
                        : Navigator.of(context).pushNamed(Routes.receive),
                    textColor: Theme.of(context).extension<SyncIndicatorTheme>()!.textColor,
                    color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                    borderColor: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
                    arrowColor: Theme.of(context).extension<SyncIndicatorTheme>()!.textColor,
                    textSize: 14,
                    height: 50,
                  );
                } else if (dashboardViewModel.isAutoGenerateSubaddressesEnabled ||
                    addressListViewModel.isElectrumWallet) {
                  return Text(S.of(context).electrum_address_disclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor));
                } else {
                  return const SizedBox();
                }
              })
            ],
          ),
        ));
  }

  void _setEffects(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) {
      switch (option) {
        case ReceivePageOption.anonPayInvoice:
          Navigator.pushNamed(
            context,
            Routes.anonPayInvoicePage,
            arguments: [addressListViewModel.address.address, option],
          );
          break;
        case ReceivePageOption.anonPayDonationLink:
          final sharedPreferences = getIt.get<SharedPreferences>();
          final clearnetUrl = sharedPreferences.getString(PreferencesKey.clearnetDonationLink);
          final onionUrl = sharedPreferences.getString(PreferencesKey.onionDonationLink);

          if (clearnetUrl != null && onionUrl != null) {
            Navigator.pushNamed(
              context,
              Routes.anonPayReceivePage,
              arguments: AnonpayDonationLinkInfo(
                clearnetUrl: clearnetUrl,
                onionUrl: onionUrl,
                address: addressListViewModel.address.address,
              ),
            );
          } else {
            Navigator.pushNamed(
              context,
              Routes.anonPayInvoicePage,
              arguments: [addressListViewModel.address.address, option],
            );
          }
          break;
        default:
          if (addressListViewModel.type == WalletType.bitcoin) {
            addressListViewModel.setAddressType(bitcoin!.getBitcoinAddressType(option));
          }
      }
    });

    effectsInstalled = true;
  }
}
