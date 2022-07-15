import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';
import 'package:cake_wallet/view_model/settings/version_list_item.dart';
import 'package:cake_wallet/view_model/settings/picker_list_item.dart';
import 'package:cake_wallet/view_model/settings/regular_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:cake_wallet/view_model/settings/switcher_list_item.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/wallet_type_utils.dart';

part 'settings_view_model.g.dart';

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

List<TransactionPriority> priorityForWalletType(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return monero.getTransactionPriorities();
    case WalletType.bitcoin:
      return bitcoin.getTransactionPriorities();
    case WalletType.litecoin:
      return bitcoin.getLitecoinTransactionPriorities();
    case WalletType.haven:
      return haven.getTransactionPriorities();
    default:
      return [];
  }
}

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(
      this._settingsStore,
      this._yatStore,
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet)
      : itemHeaders = {},
        _walletType = wallet.type,
        _biometricAuth = BiometricAuth() {
    currentVersion = '';
    PackageInfo.fromPlatform().then(
        (PackageInfo packageInfo) => currentVersion = packageInfo.version);

    final priority = _settingsStore.priority[wallet.type];
    final priorities = priorityForWalletType(wallet.type);

    if (!priorities.contains(priority)) {
      _settingsStore.priority[wallet.type] = priorities.first;
    }

    //var connectYatUrl = YatLink.baseUrl + YatLink.signInSuffix;
    //final connectYatUrlParameters =
    //    _yatStore.defineQueryParameters();

    //if (connectYatUrlParameters.isNotEmpty) {
    //  connectYatUrl += YatLink.queryParameter + connectYatUrlParameters;
    //}

    //var manageYatUrl = YatLink.baseUrl + YatLink.managePath;
    //final manageYatUrlParameters =
    //    _yatStore.defineQueryParameters();

    //if (manageYatUrlParameters.isNotEmpty) {
    //  manageYatUrl += YatLink.queryParameter + manageYatUrlParameters;
    //}

    //var createNewYatUrl = YatLink.startFlowUrl;
    //final createNewYatUrlParameters =
    //    _yatStore.defineQueryParameters();

    //if (createNewYatUrlParameters.isNotEmpty) {
    //  createNewYatUrl += '?sub1=' + createNewYatUrlParameters;
    //}


    getSections = () => [
      [
        SwitcherListItem(
            title: S.current.settings_display_balance,
            value: () => balanceDisplayMode == BalanceDisplayMode.displayableBalance,
            onValueChange: (_, bool value) {
              if (value) {
                _settingsStore.balanceDisplayMode = BalanceDisplayMode.displayableBalance;
              } else {
                _settingsStore.balanceDisplayMode = BalanceDisplayMode.hiddenBalance;
              }
            },
        ),
        if (!isHaven && !shouldDisableFiat)
          PickerListItem(
              title: S.current.settings_currency,
              searchHintText: S.current.search_currency,
              items: FiatCurrency.all,
              selectedItem: () => fiatCurrency,
              onItemSelected: (FiatCurrency currency) =>
                  setFiatCurrency(currency),
              images: FiatCurrency.all.map(
                    (e) => Image.asset("assets/images/flags/${e.countryCode}.png"))
                .toList(),
              isGridView: true,
              matchingCriteria: (FiatCurrency currency, String searchText) {
                return currency.title.toLowerCase().contains(searchText) || currency.fullName.toLowerCase().contains(searchText);
              },
          ),
        PickerListItem(
            title: S.current.settings_fee_priority,
            items: priorityForWalletType(wallet.type),
            displayItem: (dynamic priority) {
              final _priority = priority as TransactionPriority;

              if (wallet.type == WalletType.bitcoin
                  || wallet.type == WalletType.litecoin) {
                final rate = bitcoin.getFeeRate(wallet, _priority);
                return '${priority.labelWithRate(rate)}';
              }

              return priority.toString();
            },
            selectedItem: () => transactionPriority,
            onItemSelected: (TransactionPriority priority) =>
                _settingsStore.priority[wallet.type] = priority),
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
        PickerListItem(
            title: S.current.settings_change_language,
            searchHintText: S.current.search_language,
            items: LanguageService.list.keys.toList(),
            displayItem: (dynamic code) {
              return LanguageService.list[code];
            },
            selectedItem: () => _settingsStore.languageCode,
            onItemSelected: (String code) {
              _settingsStore.languageCode = code;
            },
            images: LanguageService.list.keys.map(
              (e) => Image.asset("assets/images/flags/${LanguageService.localeCountryCode[e]}.png"))
              .toList(),
            matchingCriteria: (String code, String searchText) {
              return LanguageService.list[code].toLowerCase().contains(searchText);
            },
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
        SwitcherListItem(
          title: S.current.disable_fiat,
          value: () => shouldDisableFiat,
          onValueChange: (_, bool value) =>
              setShouldDisableFiat(value)
        ),
        ChoicesListItem(
          title: S.current.color_theme,
          items: ThemeList.all,
          selectedItem: theme,
          onItemSelected: (ThemeBase theme) => _settingsStore.currentTheme = theme,
        ),
      ],
      //[
        //if (_yatStore.emoji.isNotEmpty) ...[
        //  LinkListItem(
        //      title: S.current.manage_yats,
        //      link: manageYatUrl,
        //      linkTitle: ''),
        //] else ...[
        //LinkListItem(
        //  title: S.current.connect_yats,
        //  link: connectYatUrl,
        //  linkTitle: ''),
        //LinkListItem(
        //  title: 'Create new Yats',
        //  link: createNewYatUrl,
        //  linkTitle: '')
        //]
      //],
      [
        RegularListItem(
          title: S.current.settings_terms_and_conditions,
          handler: (BuildContext context) =>
              Navigator.of(context).pushNamed(Routes.readDisclaimer),
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
      _settingsStore.priority[_walletType];

  @computed
  BalanceDisplayMode get balanceDisplayMode =>
      _settingsStore.balanceDisplayMode;

  @computed
  bool get shouldSaveRecipientAddress =>
      _settingsStore.shouldSaveRecipientAddress;

  @computed
  bool get shouldDisableFiat =>
      _settingsStore.shouldDisableFiat;

  @computed
  bool get allowBiometricalAuthentication =>
      _settingsStore.allowBiometricalAuthentication;

  @computed
  ThemeBase get theme => _settingsStore.currentTheme;

  bool get isBitcoinBuyEnabled => _settingsStore.isBitcoinBuyEnabled;

  final Map<String, String> itemHeaders;
  List<List<SettingsListItem>> Function() getSections;
  final SettingsStore _settingsStore;
  final YatStore _yatStore;
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
  void setShouldDisableFiat(bool value) =>
      _settingsStore.shouldDisableFiat= value;

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
