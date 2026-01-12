import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/anonpay/anonpay_donation_link_info.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/src/screens/receive/anonpay_receive_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_receive_option_picker.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/share_util.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
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
        addressListViewModel.changeAmount(_amountController.text);
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
      color: Theme.of(context).colorScheme.primary,
      size: 16,
    );
    final _closeButton = currentTheme.isDark ? closeButtonImageDarkTheme : closeButtonImage;

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
                overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
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
          icon: Icon(Icons.share, size: 20, color: Theme.of(context).colorScheme.primary),
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
        keyboardBarColor: Theme.of(context).colorScheme.surface,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: _cryptoAmountFocus,
            toolbarButtons: [(_) => KeyboardDoneButton()],
          )
        ],
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          children: <Widget>[
            Expanded(
              child: QRWidget(
                formKey: _formKey,
                addressListViewModel: addressListViewModel,
                amountTextFieldFocusNode: _cryptoAmountFocus,
                amountController: _amountController,
              ),
            ),
            SizedBox(height: 16),
            Observer(
              builder: (_) {
                if (addressListViewModel.hasAddressList) {
                  return SelectButton(
                    text: addressListViewModel.buttonTitle,
                    onTap: () => Navigator.of(context).pushNamed(Routes.receive),
                    textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    arrowColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textSize: 14,
                    height: 50,
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
            if (addressListViewModel.hasTokensList) ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CakeImageWidget(
                          imageUrl: addressListViewModel.monoImage,
                          height: 16,
                          width: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 10),
                        Text(
                          '${S.current.your} ${addressListViewModel.walletTypeName} ${S.current.address}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${S.current.qr_instruction} ${addressListViewModel.walletTypeName}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        height: 40,
                        width: addressListViewModel.walletImages.length * 32.0,
                        child: Stack(
                          children: [
                            for (int i = addressListViewModel.walletImages.length - 1; i >= 0; i--)
                              Positioned(
                                left: i * 25.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                      width: 3,
                                    ),
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: ClipOval(
                                    child: CakeImageWidget(
                                      height: 35,
                                      width: 35,
                                      imageUrl: addressListViewModel.walletImages[i],
                                      color: addressListViewModel.walletImages.last ==
                                              addressListViewModel.walletImages[i]
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }

  void _setEffects(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => receiveOptionViewModel.selectedReceiveOption, (ReceivePageOption option) {
      if (dashboardViewModel.type == WalletType.bitcoin &&
          bitcoin!.isBitcoinReceivePageOption(option)) {
        addressListViewModel.setAddressType(bitcoin!.getOptionToType(option));
        return;
      }
      if (dashboardViewModel.type == WalletType.zcash) {
        addressListViewModel.setAddressType(zcash!.getOptionToType(option));
        return;
      }

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
          final donationWalletName =
              sharedPreferences.getString(PreferencesKey.donationLinkWalletName);

          if (clearnetUrl != null &&
              onionUrl != null &&
              addressListViewModel.wallet.name == donationWalletName) {
            Navigator.pushNamed(
              context,
              Routes.anonPayReceivePage,
              arguments: AnonPayReceivePageArgs(
                invoiceInfo: AnonpayDonationLinkInfo(
                  clearnetUrl: clearnetUrl,
                  onionUrl: onionUrl,
                  address: addressListViewModel.address.address,
                ),
                qrImage: addressListViewModel.qrImage,
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
          if (addressListViewModel.type == WalletType.bitcoin ||
              addressListViewModel.type == WalletType.litecoin) {
            addressListViewModel.setAddressType(bitcoin!.getBitcoinAddressType(option));
          }
          if (addressListViewModel.type == WalletType.zcash) {
            printV("help me i'll kms if that wont work: ${zcash!.getZcashAddressType(option)}");
            addressListViewModel.setAddressType(zcash!.getZcashAddressType(option));
          }
      }
    });

    effectsInstalled = true;
  }
}
