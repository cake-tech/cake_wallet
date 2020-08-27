import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_display_mode.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/view_model/settings/link_list_item.dart';
import 'package:cake_wallet/view_model/settings/picker_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';

part 'settings_view_model.g.dart';

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(this._settingsStore, WalletBase wallet)
      : itemHeaders = {},
        _walletType = wallet.type {
    sections = [
      [
        PickerListItem(
            title: S.current.settings_display_balance_as,
            items: BalanceDisplayMode.all,
            selectedItem: () => balanceDisplayMode),
        PickerListItem(
            title: S.current.settings_currency,
            items: FiatCurrency.all,
            selectedItem: () => fiatCurrency),
        PickerListItem(
            title: S.current.settings_fee_priority,
            items: _transactionPriorities(wallet.type),
            selectedItem: () => transactionPriority,
            onItemSelected: (TransactionPriority priority) =>
                _settingsStore.transactionPriority = priority),
        SwitcherListItem(
            title: S.current.settings_save_recipient_address,
            value: () => shouldSaveRecipientAddress,
            onValueChange: (bool value) => shouldSaveRecipientAddress = value)
      ],
      [
        RegularListItem(
            title: S.current.settings_change_pin,
            handler: (BuildContext context) {
              Navigator.of(context).pushNamed(Routes.auth,
                  arguments: (bool isAuthenticatedSuccessfully,
                          AuthPageState auth) =>
                      isAuthenticatedSuccessfully
                          ? Navigator.of(context).popAndPushNamed(
                              Routes.setupPin,
                              arguments:
                                  (BuildContext setupPinContext, String _) =>
                                      Navigator.of(context).pop())
                          : null);
            }),
        RegularListItem(
          title: S.current.settings_change_language,
          handler: (BuildContext context) =>
              Navigator.of(context).pushNamed(Routes.changeLanguage),
        ),
        SwitcherListItem(
            title: S.current.settings_allow_biometrical_authentication,
            value: () => allowBiometricalAuthentication,
            onValueChange: (bool value) =>
                allowBiometricalAuthentication = value),
        SwitcherListItem(
            title: S.current.settings_dark_mode,
            value: () => _settingsStore.isDarkTheme,
            onValueChange: (bool value) {
              // FIXME: Implement me
            })
      ],
      [
        LinkListItem(
            title: 'Email',
            linkTitle: 'support@cakewallet.com',
            link: 'mailto:support@cakewallet.com'),
        LinkListItem(
            title: 'Telegram',
            icon: 'assets/images/Telegram.png',
            linkTitle: 'Cake_Wallet',
            link: 'https:t.me/cakewallet_bot'),
        LinkListItem(
            title: 'Twitter',
            icon: 'assets/images/Twitter.png',
            linkTitle: '@CakeWalletXMR',
            link: 'https:twitter.com/CakewalletXMR'),
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
              Navigator.of(context).pushNamed(Routes.disclaimer),
        )
      ]
    ];
  }

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

  @action
  set shouldSaveRecipientAddress(bool value) =>
      _settingsStore.shouldSaveRecipientAddress = value;

  @computed
  bool get allowBiometricalAuthentication =>
      _settingsStore.allowBiometricalAuthentication;

  @action
  set allowBiometricalAuthentication(bool value) =>
      _settingsStore.allowBiometricalAuthentication = value;

  final Map<String, String> itemHeaders;
  final SettingsStore _settingsStore;
  final WalletType _walletType;
  List<List<SettingsListItem>> sections;

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

//
//  @observable
//  int defaultPinLength;
//  bool isDarkTheme;

  static List<TransactionPriority> _transactionPriorities(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return TransactionPriority.all;
      case WalletType.bitcoin:
        return [
          TransactionPriority.slow,
          TransactionPriority.regular,
          TransactionPriority.fast
        ];
      default:
        return [];
    }
  }
}
