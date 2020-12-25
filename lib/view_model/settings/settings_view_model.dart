import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';
import 'package:cake_wallet/view_model/settings/version_list_item.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/picker_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';

part 'settings_view_model.g.dart';

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(this._settingsStore, WalletBase wallet)
      : itemHeaders = {},
        _walletType = wallet.type,
        _biometricAuth = BiometricAuth() {
    currentVersion = '';
    PackageInfo.fromPlatform().then(
        (PackageInfo packageInfo) => currentVersion = packageInfo.version);
    sections = [
      [
        if ((wallet.balance.availableModes as List).length > 1)
          PickerListItem(
              title: S.current.settings_display_balance_as,
              items: BalanceDisplayMode.all,
              selectedItem: () => balanceDisplayMode,
              onItemSelected: (BalanceDisplayMode mode) =>
                  _settingsStore.balanceDisplayMode = mode),
        PickerListItem(
            title: S.current.settings_currency,
            items: FiatCurrency.all,
            isAlwaysShowScrollThumb: true,
            selectedItem: () => fiatCurrency,
            onItemSelected: (FiatCurrency currency) =>
                setFiatCurrency(currency)),
        PickerListItem(
            title: S.current.settings_fee_priority,
            items: TransactionPriority.forWalletType(wallet.type),
            selectedItem: () => transactionPriority,
            isAlwaysShowScrollThumb: true,
            onItemSelected: (TransactionPriority priority) =>
                _settingsStore.transactionPriority = priority),
        SwitcherListItem(
            title: S.current.settings_save_recipient_address,
            value: () => shouldSaveRecipientAddress,
            onValueChange: (_, bool value) =>
                setShouldSaveRecipientAddress(value))
      ],
      [
        RegularListItem(
            title: S.current.settings_change_pin,
            handler: (BuildContext context) {
              Navigator.of(context).pushNamed(Routes.auth, arguments:
                  (bool isAuthenticatedSuccessfully, AuthPageState auth) {
                auth.close();
                if (isAuthenticatedSuccessfully) {
                  Navigator.of(context).pushNamed(Routes.setupPin, arguments:
                      (PinCodeState<PinCodeWidget> setupPinContext, String _) {
                    setupPinContext.close();
                  });
                }
              });
            }),
        RegularListItem(
          title: S.current.settings_change_language,
          handler: (BuildContext context) =>
              Navigator.of(context).pushNamed(Routes.changeLanguage),
        ),
        SwitcherListItem(
            title: S.current.settings_allow_biometrical_authentication,
            value: () => allowBiometricalAuthentication,
            onValueChange: (BuildContext context, bool value) {
              if (value) {
                Navigator.of(context).pushNamed(Routes.auth, arguments:
                    (bool isAuthenticatedSuccessfully,
                        AuthPageState auth) async {
                  if (isAuthenticatedSuccessfully) {
                    if (await _biometricAuth.canCheckBiometrics() &&
                        await _biometricAuth.isAuthenticated()) {
                      setAllowBiometricalAuthentication(
                          isAuthenticatedSuccessfully);
                    }
                  } else {
                    setAllowBiometricalAuthentication(
                        isAuthenticatedSuccessfully);
                  }

                  auth.close();
                });
              } else {
                setAllowBiometricalAuthentication(value);
              }
            }),
        PickerListItem(
            title: S.current.color_theme,
            items: ThemeList.all,
            selectedItem: () => theme,
            onItemSelected: (ThemeBase theme) =>
            _settingsStore.currentTheme = theme)
      ],
      [
        LinkListItem(
            title: 'Email',
            linkTitle: 'support@cakewallet.com',
            link: 'mailto:support@cakewallet.com'),
        LinkListItem(
            title: 'Telegram',
            icon: 'assets/images/Telegram.png',
            linkTitle: '@cakewallet_bot',
            link: 'https:t.me/cakewallet_bot'),
        LinkListItem(
            title: 'Twitter',
            icon: 'assets/images/Twitter.png',
            linkTitle: '@cakewallet',
            link: 'https://twitter.com/cakewallet'),
        LinkListItem(
            title: 'ChangeNow',
            icon: 'assets/images/change_now.png',
            linkTitle: 'support@changenow.io',
            link: 'mailto:support@changenow.io'),
        LinkListItem(
            title: 'Morph',
            icon: 'assets/images/morph_icon.png',
            linkTitle: 'support@morphtoken.com',
            link: 'mailto:support@morphtoken.com'),
        LinkListItem(
            title: 'XMR.to',
            icon: 'assets/images/xmr_btc.png',
            linkTitle: 'support@xmr.to',
            link: 'mailto:support@xmr.to'),
        RegularListItem(
          title: S.current.settings_terms_and_conditions,
          handler: (BuildContext context) =>
              Navigator.of(context).pushNamed(Routes.readDisclaimer),
        ),
        RegularListItem(
          title: S.current.faq,
          handler: (BuildContext context) =>
              Navigator.pushNamed(context, Routes.faq),
        )
      ],
      [VersionListItem(title: currentVersion)]
    ];
  }

  @observable
  String currentVersion;

  @computed
  Node get node => _settingsStore.getCurrentNode(_walletType);

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  @computed
  ObservableList<ActionListDisplayMode> get actionlistDisplayMode =>
      _settingsStore.actionlistDisplayMode;

  @computed
  TransactionPriority get transactionPriority =>
      _settingsStore.transactionPriority;

  @computed
  BalanceDisplayMode get balanceDisplayMode =>
      _settingsStore.balanceDisplayMode;

  @computed
  bool get shouldSaveRecipientAddress =>
      _settingsStore.shouldSaveRecipientAddress;

  @computed
  bool get allowBiometricalAuthentication =>
      _settingsStore.allowBiometricalAuthentication;

  @computed
  ThemeBase get theme => _settingsStore.currentTheme;

  final Map<String, String> itemHeaders;
  List<List<SettingsListItem>> sections;
  final SettingsStore _settingsStore;
  final WalletType _walletType;
  final BiometricAuth _biometricAuth;

  @action
  void setBalanceDisplayMode(BalanceDisplayMode value) =>
      _settingsStore.balanceDisplayMode = value;

  @action
  void setFiatCurrency(FiatCurrency value) =>
      _settingsStore.fiatCurrency = value;

  @action
  void setShouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;

  @action
  void setAllowBiometricalAuthentication(bool value) =>
      _settingsStore.allowBiometricalAuthentication = value;

  @action
  void toggleTransactionsDisplay() =>
      actionlistDisplayMode.contains(ActionListDisplayMode.transactions)
          ? _hideTransaction()
          : _showTransaction();

  @action
  void toggleTradesDisplay() =>
      actionlistDisplayMode.contains(ActionListDisplayMode.trades)
          ? _hideTrades()
          : _showTrades();

  @action
  void _hideTransaction() =>
      actionlistDisplayMode.remove(ActionListDisplayMode.transactions);

  @action
  void _hideTrades() =>
      actionlistDisplayMode.remove(ActionListDisplayMode.trades);

  @action
  void _showTransaction() =>
      actionlistDisplayMode.add(ActionListDisplayMode.transactions);

  @action
  void _showTrades() => actionlistDisplayMode.add(ActionListDisplayMode.trades);
}
