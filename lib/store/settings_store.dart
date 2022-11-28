import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';

part 'settings_store.g.dart';

class SettingsStore = SettingsStoreBase with _$SettingsStore;

abstract class SettingsStoreBase with Store {
  SettingsStoreBase(
      {required SharedPreferences sharedPreferences,
      required FiatCurrency initialFiatCurrency,
      required BalanceDisplayMode initialBalanceDisplayMode,
      required bool initialSaveRecipientAddress,
      required bool initialAllowBiometricalAuthentication,
      required bool initialExchangeEnabled,
      required ThemeBase initialTheme,
      required int initialPinLength,
      required String initialLanguageCode,
      // required String initialCurrentLocale,
      required this.appVersion,
      required Map<WalletType, Node> nodes,
      required this.shouldShowYatPopup,
      required this.isBitcoinBuyEnabled,
      required this.actionlistDisplayMode,
      required this.pinTimeOutDuration,
      TransactionPriority? initialBitcoinTransactionPriority,
      TransactionPriority? initialMoneroTransactionPriority})
  : nodes = ObservableMap<WalletType, Node>.of(nodes),
    _sharedPreferences = sharedPreferences,
    fiatCurrency = initialFiatCurrency,
    balanceDisplayMode = initialBalanceDisplayMode,
    shouldSaveRecipientAddress = initialSaveRecipientAddress,
    allowBiometricalAuthentication = initialAllowBiometricalAuthentication,
    disableExchange = initialExchangeEnabled,
    currentTheme = initialTheme,
    pinCodeLength = initialPinLength,
    languageCode = initialLanguageCode,
    priority = ObservableMap<WalletType, TransactionPriority>() {
    //this.nodes = ObservableMap<WalletType, Node>.of(nodes);

    if (initialMoneroTransactionPriority != null) {
        priority[WalletType.monero] = initialMoneroTransactionPriority;
    }

    if (initialBitcoinTransactionPriority != null) {
        priority[WalletType.bitcoin] = initialBitcoinTransactionPriority;
    }

    reaction(
        (_) => fiatCurrency,
        (FiatCurrency fiatCurrency) => sharedPreferences.setString(
            PreferencesKey.currentFiatCurrencyKey, fiatCurrency.serialize()));

    reaction(
        (_) => shouldShowYatPopup,
        (bool shouldShowYatPopup) => sharedPreferences
             .setBool(PreferencesKey.shouldShowYatPopup, shouldShowYatPopup));

    priority.observe((change) {
      final key = change.key == WalletType.monero
          ? PreferencesKey.moneroTransactionPriority
          : PreferencesKey.bitcoinTransactionPriority;

      if (change.newValue != null) {
        sharedPreferences.setInt(key, change.newValue!.serialize());
      }
    });

    reaction(
        (_) => shouldSaveRecipientAddress,
        (bool shouldSaveRecipientAddress) => sharedPreferences.setBool(
            PreferencesKey.shouldSaveRecipientAddressKey,
            shouldSaveRecipientAddress));

    reaction(
        (_) => currentTheme,
        (ThemeBase theme) =>
            sharedPreferences.setInt(PreferencesKey.currentTheme, theme.raw));

    reaction(
        (_) => allowBiometricalAuthentication,
        (bool biometricalAuthentication) => sharedPreferences.setBool(
            PreferencesKey.allowBiometricalAuthenticationKey,
            biometricalAuthentication));

    reaction(
        (_) => pinCodeLength,
        (int pinLength) => sharedPreferences.setInt(
            PreferencesKey.currentPinLength, pinLength));

    reaction(
        (_) => languageCode,
        (String languageCode) => sharedPreferences.setString(
            PreferencesKey.currentLanguageCode, languageCode));

    reaction(
        (_) => pinTimeOutDuration,
        (PinCodeRequiredDuration pinCodeInterval) => sharedPreferences.setInt(
            PreferencesKey.pinTimeOutDuration, pinCodeInterval.value));

    reaction(
        (_) => balanceDisplayMode,
        (BalanceDisplayMode mode) => sharedPreferences.setInt(
            PreferencesKey.currentBalanceDisplayModeKey, mode.serialize()));

    this
        .nodes
        .observe((change) { 
            if (change.newValue != null && change.key != null) {
                _saveCurrentNode(change.newValue!, change.key!);
            }
        });
  }

  static const defaultPinLength = 4;
  static const defaultActionsMode = 11;
  static const defaultPinCodeTimeOutDuration = 10;

  @observable
  FiatCurrency fiatCurrency;

  @observable
  bool shouldShowYatPopup;

  @observable
  ObservableList<ActionListDisplayMode> actionlistDisplayMode;

  @observable
  BalanceDisplayMode balanceDisplayMode;

  @observable
  bool shouldSaveRecipientAddress;

  @observable
  bool allowBiometricalAuthentication;

  @observable
  bool disableExchange;

  @observable
  ThemeBase currentTheme;

  @observable
  int pinCodeLength;

  @observable
  PinCodeRequiredDuration pinTimeOutDuration;

  @computed
  ThemeData get theme => currentTheme.themeData;

  @observable
  String languageCode;

  @observable
  ObservableMap<WalletType, TransactionPriority> priority;

  String appVersion;

  SharedPreferences _sharedPreferences;

  ObservableMap<WalletType, Node> nodes;

  Node getCurrentNode(WalletType walletType) {
    final node = nodes[walletType];

    if (node == null) {
        throw Exception('No node found for wallet type: ${walletType.toString()}');
    }

    return node;
  }

  bool isBitcoinBuyEnabled;

  bool get shouldShowReceiveWarning =>
    _sharedPreferences.getBool(PreferencesKey.shouldShowReceiveWarning) ?? true;

  Future<void> setShouldShowReceiveWarning(bool value) async =>
    _sharedPreferences.setBool(PreferencesKey.shouldShowReceiveWarning, value);

  static Future<SettingsStore> load(
      {required Box<Node> nodeSource,
      required bool isBitcoinBuyEnabled,
      TransactionPriority? initialMoneroTransactionPriority,
      TransactionPriority? initialBitcoinTransactionPriority,
      FiatCurrency initialFiatCurrency = FiatCurrency.usd,
      BalanceDisplayMode initialBalanceDisplayMode =
          BalanceDisplayMode.availableBalance}) async {
    if (initialBitcoinTransactionPriority == null) {
        initialBitcoinTransactionPriority = bitcoin?.getMediumTransactionPriority();
    }

    if (initialMoneroTransactionPriority == null) {
        initialMoneroTransactionPriority = monero?.getDefaultTransactionPriority();
    }

    final sharedPreferences = await getIt.getAsync<SharedPreferences>();
    final currentFiatCurrency = FiatCurrency.deserialize(raw:
            sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey)!);
    final savedMoneroTransactionPriority =
        monero?.deserializeMoneroTransactionPriority(
            raw: sharedPreferences
                .getInt(PreferencesKey.moneroTransactionPriority)!);
    final savedBitcoinTransactionPriority =
        bitcoin?.deserializeBitcoinTransactionPriority(sharedPreferences
                .getInt(PreferencesKey.bitcoinTransactionPriority)!);
    final moneroTransactionPriority =
        savedMoneroTransactionPriority ?? initialMoneroTransactionPriority;
    final bitcoinTransactionPriority =
        savedBitcoinTransactionPriority ?? initialBitcoinTransactionPriority;
    final currentBalanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentBalanceDisplayModeKey)!);
    // FIX-ME: Check for which default value we should have here
    final shouldSaveRecipientAddress =
        sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey) ?? false;
    final allowBiometricalAuthentication = sharedPreferences
            .getBool(PreferencesKey.allowBiometricalAuthenticationKey) ??
        false;
    final disableExchange = sharedPreferences
            .getBool(PreferencesKey.disableExchangeKey) ?? false;
    final legacyTheme =
        (sharedPreferences.getBool(PreferencesKey.isDarkThemeLegacy) ?? false)
            ? ThemeType.dark.index
            : ThemeType.bright.index;
    final savedTheme = ThemeList.deserialize(
        raw: sharedPreferences.getInt(PreferencesKey.currentTheme) ??
            legacyTheme);
    final actionListDisplayMode = ObservableList<ActionListDisplayMode>();
    actionListDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(PreferencesKey.displayActionListModeKey) ??
            defaultActionsMode));
    var pinLength = sharedPreferences.getInt(PreferencesKey.currentPinLength);
    final pinCodeTimeOutDuration = PinCodeRequiredDuration.deserialize(raw: sharedPreferences.getInt(PreferencesKey.pinTimeOutDuration) 
      ?? defaultPinCodeTimeOutDuration);
    
    // If no value
    if (pinLength == null || pinLength == 0) {
      pinLength = defaultPinLength;
    }

    final savedLanguageCode =
        sharedPreferences.getString(PreferencesKey.currentLanguageCode) ??
            await LanguageService.localeDetection();
    final nodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
    final bitcoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
    final litecoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentLitecoinElectrumSererIdKey);
    final havenNodeId = sharedPreferences
        .getInt(PreferencesKey.currentHavenNodeIdKey);
    final moneroNode = nodeSource.get(nodeId);
    final bitcoinElectrumServer = nodeSource.get(bitcoinElectrumServerId);
    final litecoinElectrumServer = nodeSource.get(litecoinElectrumServerId);
    final havenNode = nodeSource.get(havenNodeId);
    final packageInfo = await PackageInfo.fromPlatform();
    final shouldShowYatPopup =
        sharedPreferences.getBool(PreferencesKey.shouldShowYatPopup) ?? true;

    final nodes = <WalletType, Node>{};

    if (moneroNode != null) {
        nodes[WalletType.monero] = moneroNode;
    }

    if (bitcoinElectrumServer != null) {
        nodes[WalletType.bitcoin] = bitcoinElectrumServer;
    }

    if (litecoinElectrumServer != null) {
        nodes[WalletType.litecoin] = litecoinElectrumServer;
    }

    if (havenNode != null) {
        nodes[WalletType.haven] = havenNode;
    }
    
    return SettingsStore(
        sharedPreferences: sharedPreferences,
        nodes: nodes,
        appVersion: packageInfo.version,
        isBitcoinBuyEnabled: isBitcoinBuyEnabled,
        initialFiatCurrency: currentFiatCurrency,
        initialBalanceDisplayMode: currentBalanceDisplayMode,
        initialSaveRecipientAddress: shouldSaveRecipientAddress,
        initialAllowBiometricalAuthentication: allowBiometricalAuthentication,
        initialExchangeEnabled: disableExchange,
        initialTheme: savedTheme,
        actionlistDisplayMode: actionListDisplayMode,
        initialPinLength: pinLength,
        pinTimeOutDuration: pinCodeTimeOutDuration,
        initialLanguageCode: savedLanguageCode,
        initialMoneroTransactionPriority: moneroTransactionPriority,
        initialBitcoinTransactionPriority: bitcoinTransactionPriority,
        shouldShowYatPopup: shouldShowYatPopup);
  }

  // FIX-ME: Dead code

  //Future<void> reload(
  //    {required Box<Node> nodeSource,
  //    FiatCurrency initialFiatCurrency = FiatCurrency.usd,
  //    TransactionPriority? initialMoneroTransactionPriority,
  //    TransactionPriority? initialBitcoinTransactionPriority,
  //    BalanceDisplayMode initialBalanceDisplayMode =
  //        BalanceDisplayMode.availableBalance}) async {
    
  //  if (initialBitcoinTransactionPriority == null) {
  //      initialBitcoinTransactionPriority = bitcoin?.getMediumTransactionPriority();
  //  }

  //  if (initialMoneroTransactionPriority == null) {
  //      initialMoneroTransactionPriority = monero?.getDefaultTransactionPriority();
  //  }

  //  final isBitcoinBuyEnabled = (secrets.wyreSecretKey?.isNotEmpty ?? false) &&
  //      (secrets.wyreApiKey?.isNotEmpty ?? false) &&
  //      (secrets.wyreAccountId?.isNotEmpty ?? false);

  //  final settings = await SettingsStoreBase.load(
  //      nodeSource: nodeSource,
  //      isBitcoinBuyEnabled: isBitcoinBuyEnabled,
  //      initialBalanceDisplayMode: initialBalanceDisplayMode,
  //      initialFiatCurrency: initialFiatCurrency,
  //      initialMoneroTransactionPriority: initialMoneroTransactionPriority,
  //      initialBitcoinTransactionPriority: initialBitcoinTransactionPriority);
  //  fiatCurrency = settings.fiatCurrency;
  //  actionlistDisplayMode = settings.actionlistDisplayMode;
  //  priority[WalletType.monero] = initialMoneroTransactionPriority;
  //  priority[WalletType.bitcoin] = initialBitcoinTransactionPriority;
  //  balanceDisplayMode = settings.balanceDisplayMode;
  //  shouldSaveRecipientAddress = settings.shouldSaveRecipientAddress;
  //  allowBiometricalAuthentication = settings.allowBiometricalAuthentication;
  //  currentTheme = settings.currentTheme;
  //  pinCodeLength = settings.pinCodeLength;
  //  languageCode = settings.languageCode;
  //  appVersion = settings.appVersion;
  //  shouldShowYatPopup = settings.shouldShowYatPopup;
  //}

  Future<void> _saveCurrentNode(Node node, WalletType walletType) async {
    switch (walletType) {
      case WalletType.bitcoin:
        await _sharedPreferences.setInt(
            PreferencesKey.currentBitcoinElectrumSererIdKey, node.key as int);
        break;
      case WalletType.litecoin:
        await _sharedPreferences.setInt(
            PreferencesKey.currentLitecoinElectrumSererIdKey, node.key as int);
        break;
      case WalletType.monero:
        await _sharedPreferences.setInt(
            PreferencesKey.currentNodeIdKey, node.key as int);
        break;
      case WalletType.haven:
        await _sharedPreferences.setInt(
            PreferencesKey.currentHavenNodeIdKey, node.key as int);
        break;
      default:
        break;
    }

    nodes[walletType] = node;
  }
}
