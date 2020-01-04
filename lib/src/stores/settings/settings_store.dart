import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_display_mode.dart';
import 'package:cake_wallet/src/screens/settings/items/item_headers.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'settings_store.g.dart';

class SettingsStore = SettingsStoreBase with _$SettingsStore;

abstract class SettingsStoreBase with Store {
  static const currentNodeIdKey = 'current_node_id';
  static const currentFiatCurrencyKey = 'current_fiat_currency';
  static const currentTransactionPriorityKey = 'current_fee_priority';
  static const currentBalanceDisplayModeKey = 'current_balance_display_mode';
  static const shouldSaveRecipientAddressKey = 'save_recipient_address';
  static const allowBiometricalAuthenticationKey =
      'allow_biometrical_authentication';
  static const currentDarkTheme = 'dark_theme';
  static const displayActionListModeKey = 'display_list_mode';
  static const currentPinLength = 'current_pin_length';
  static const currentLanguageCode = 'language_code';

  static Future<SettingsStore> load(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes,
      @required FiatCurrency initialFiatCurrency,
      @required TransactionPriority initialTransactionPriority,
      @required BalanceDisplayMode initialBalanceDisplayMode}) async {
    final currentFiatCurrency = FiatCurrency(
        symbol: sharedPreferences.getString(currentFiatCurrencyKey));
    final currentTransactionPriority = TransactionPriority.deserialize(
        raw: sharedPreferences.getInt(currentTransactionPriorityKey));
    final currentBalanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences.getInt(currentBalanceDisplayModeKey));
    final shouldSaveRecipientAddress =
        sharedPreferences.getBool(shouldSaveRecipientAddressKey);
    final allowBiometricalAuthentication =
        sharedPreferences.getBool(allowBiometricalAuthenticationKey) == null
            ? false
            : sharedPreferences.getBool(allowBiometricalAuthenticationKey);
    final savedDarkTheme = sharedPreferences.getBool(currentDarkTheme) == null
        ? false
        : sharedPreferences.getBool(currentDarkTheme);
    final actionlistDisplayMode = ObservableList<ActionListDisplayMode>();
    actionlistDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(displayActionListModeKey) ?? 11));
    final defaultPinLength = sharedPreferences.getInt(currentPinLength) == null
        ? 4
        : sharedPreferences.getInt(currentPinLength);
    final savedLanguageCode =
        sharedPreferences.getString(currentLanguageCode) == null
            ? 'en'
            : sharedPreferences.getString(currentLanguageCode);

    final store = SettingsStore(
        sharedPreferences: sharedPreferences,
        nodes: nodes,
        initialFiatCurrency: currentFiatCurrency,
        initialTransactionPriority: currentTransactionPriority,
        initialBalanceDisplayMode: currentBalanceDisplayMode,
        initialSaveRecipientAddress: shouldSaveRecipientAddress,
        initialAllowBiometricalAuthentication: allowBiometricalAuthentication,
        initialDarkTheme: savedDarkTheme,
        actionlistDisplayMode: actionlistDisplayMode,
        initialPinLength: defaultPinLength,
        initialLanguageCode: savedLanguageCode);

    await store.loadSettings();

    return store;
  }

  @observable
  Node node;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  ObservableList<ActionListDisplayMode> actionlistDisplayMode;

  @observable
  TransactionPriority transactionPriority;

  @observable
  BalanceDisplayMode balanceDisplayMode;

  @observable
  bool shouldSaveRecipientAddress;

  @observable
  bool allowBiometricalAuthentication;

  @observable
  bool isDarkTheme;

  @observable
  int defaultPinLength;
  String languageCode;

  @observable
  Map<String, String> itemHeaders;

  SharedPreferences _sharedPreferences;
  Box<Node> _nodes;

  SettingsStoreBase(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodes,
      @required FiatCurrency initialFiatCurrency,
      @required TransactionPriority initialTransactionPriority,
      @required BalanceDisplayMode initialBalanceDisplayMode,
      @required bool initialSaveRecipientAddress,
      @required bool initialAllowBiometricalAuthentication,
      @required bool initialDarkTheme,
      this.actionlistDisplayMode,
      @required int initialPinLength,
      @required String initialLanguageCode}) {
    fiatCurrency = initialFiatCurrency;
    transactionPriority = initialTransactionPriority;
    balanceDisplayMode = initialBalanceDisplayMode;
    shouldSaveRecipientAddress = initialSaveRecipientAddress;
    _sharedPreferences = sharedPreferences;
    _nodes = nodes;
    allowBiometricalAuthentication = initialAllowBiometricalAuthentication;
    isDarkTheme = initialDarkTheme;
    defaultPinLength = initialPinLength;
    languageCode = initialLanguageCode;
    itemHeaders = Map();

    actionlistDisplayMode.observe(
        (dynamic _) => _sharedPreferences.setInt(displayActionListModeKey,
            serializeActionlistDisplayModes(actionlistDisplayMode)),
        fireImmediately: false);
  }

  @action
  Future setAllowBiometricalAuthentication(
      {@required bool allowBiometricalAuthentication}) async {
    this.allowBiometricalAuthentication = allowBiometricalAuthentication;
    await _sharedPreferences.setBool(
        allowBiometricalAuthenticationKey, allowBiometricalAuthentication);
  }

  @action
  Future saveDarkTheme({@required bool isDarkTheme}) async {
    this.isDarkTheme = isDarkTheme;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: isDarkTheme ? Colors.black : Colors.white));
    await _sharedPreferences.setBool(currentDarkTheme, isDarkTheme);
  }

  @action
  Future saveLanguageCode({@required String languageCode}) async {
    this.languageCode = languageCode;
    await _sharedPreferences.setString(currentLanguageCode, languageCode);
  }

  @action
  Future setCurrentNode({@required Node node}) async {
    this.node = node;
    await _sharedPreferences.setInt(currentNodeIdKey, node.key);
  }

  @action
  Future setCurrentFiatCurrency({@required FiatCurrency currency}) async {
    this.fiatCurrency = currency;
    await _sharedPreferences.setString(
        currentFiatCurrencyKey, fiatCurrency.serialize());
  }

  @action
  Future setCurrentTransactionPriority(
      {@required TransactionPriority priority}) async {
    this.transactionPriority = priority;
    await _sharedPreferences.setInt(
        currentTransactionPriorityKey, priority.serialize());
  }

  @action
  Future setCurrentBalanceDisplayMode(
      {@required BalanceDisplayMode balanceDisplayMode}) async {
    this.balanceDisplayMode = balanceDisplayMode;
    await _sharedPreferences.setInt(
        currentBalanceDisplayModeKey, balanceDisplayMode.serialize());
  }

  @action
  Future setSaveRecipientAddress(
      {@required bool shouldSaveRecipientAddress}) async {
    this.shouldSaveRecipientAddress = shouldSaveRecipientAddress;
    await _sharedPreferences.setBool(
        shouldSaveRecipientAddressKey, shouldSaveRecipientAddress);
  }

  Future loadSettings() async => node = await _fetchCurrentNode();
  
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

  @action
  Future setDefaultPinLength({@required int pinLength}) async {
    this.defaultPinLength = pinLength;
    await _sharedPreferences.setInt(currentPinLength, pinLength);
  }

  Future<Node> _fetchCurrentNode() async {
    final id = _sharedPreferences.getInt(currentNodeIdKey);
    
    return _nodes.get(id);
  }

  @action
  void setItemHeaders() {
    itemHeaders.clear();
    itemHeaders.addAll({
      ItemHeaders.nodes: S.current.settings_nodes,
      ItemHeaders.currentNode: S.current.settings_current_node,
      ItemHeaders.wallets: S.current.settings_wallets,
      ItemHeaders.displayBalanceAs: S.current.settings_display_balance_as,
      ItemHeaders.currency: S.current.settings_currency,
      ItemHeaders.feePriority: S.current.settings_fee_priority,
      ItemHeaders.saveRecipientAddress:
          S.current.settings_save_recipient_address,
      ItemHeaders.personal: S.current.settings_personal,
      ItemHeaders.changePIN: S.current.settings_change_pin,
      ItemHeaders.changeLanguage: S.current.settings_change_language,
      ItemHeaders.allowBiometricalAuthentication:
          S.current.settings_allow_biometrical_authentication,
      ItemHeaders.darkMode: S.current.settings_dark_mode,
      ItemHeaders.support: S.current.settings_support,
      ItemHeaders.termsAndConditions: S.current.settings_terms_and_conditions,
      ItemHeaders.faq: S.current.faq
    });
  }
}
