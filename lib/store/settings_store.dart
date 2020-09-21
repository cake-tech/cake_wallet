import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/language.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';

part 'settings_store.g.dart';

class SettingsStore = SettingsStoreBase with _$SettingsStore;

abstract class SettingsStoreBase with Store {
  SettingsStoreBase(
      {@required SharedPreferences sharedPreferences,
      @required Box<Node> nodeSource,
      @required FiatCurrency initialFiatCurrency,
      @required TransactionPriority initialTransactionPriority,
      @required BalanceDisplayMode initialBalanceDisplayMode,
      @required bool initialSaveRecipientAddress,
      @required bool initialAllowBiometricalAuthentication,
      @required bool initialDarkTheme,
      @required int initialPinLength,
      @required String initialLanguageCode,
      @required String initialCurrentLocale,
      @required this.appVersion,
      @required Map<WalletType, Node> nodes,
      this.actionlistDisplayMode}) {
    fiatCurrency = initialFiatCurrency;
    transactionPriority = initialTransactionPriority;
    balanceDisplayMode = initialBalanceDisplayMode;
    shouldSaveRecipientAddress = initialSaveRecipientAddress;
    allowBiometricalAuthentication = initialAllowBiometricalAuthentication;
    isDarkTheme = initialDarkTheme;
    pinCodeLength = initialPinLength;
    languageCode = initialLanguageCode;
    currentLocale = initialCurrentLocale;
    itemHeaders = {};
    this.nodes = ObservableMap<WalletType, Node>.of(nodes);
    _sharedPreferences = sharedPreferences;
    _nodeSource = nodeSource;

    reaction(
        (_) => allowBiometricalAuthentication,
        (bool biometricalAuthentication) => sharedPreferences.setBool(
            PreferencesKey.allowBiometricalAuthenticationKey,
            biometricalAuthentication));

    reaction(
        (_) => pinCodeLength,
        (int pinLength) => sharedPreferences.setInt(
            PreferencesKey.currentPinLength, pinLength));
  }

  static const defaultPinLength = 4;
  static const defaultActionsMode = 11;

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
  int pinCodeLength;

  @observable
  Map<String, String> itemHeaders;

  String languageCode;

  String currentLocale;

  String appVersion;

  SharedPreferences _sharedPreferences;
  Box<Node> _nodeSource;

  ObservableMap<WalletType, Node> nodes;

  Node getCurrentNode(WalletType walletType) => nodes[walletType];

  static Future<SettingsStore> load(
      {@required Box<Node> nodeSource,
      FiatCurrency initialFiatCurrency = FiatCurrency.usd,
      TransactionPriority initialTransactionPriority = TransactionPriority.slow,
      BalanceDisplayMode initialBalanceDisplayMode =
          BalanceDisplayMode.availableBalance}) async {
    final sharedPreferences = await getIt.getAsync<SharedPreferences>();
    final currentFiatCurrency = FiatCurrency(
        symbol:
            sharedPreferences.getString(PreferencesKey.currentFiatCurrencyKey));
    final currentTransactionPriority = TransactionPriority.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentTransactionPriorityKey));
    final currentBalanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences
            .getInt(PreferencesKey.currentBalanceDisplayModeKey));
    final shouldSaveRecipientAddress =
        sharedPreferences.getBool(PreferencesKey.shouldSaveRecipientAddressKey);
    final allowBiometricalAuthentication = sharedPreferences
            .getBool(PreferencesKey.allowBiometricalAuthenticationKey) ??
        false;
    final savedDarkTheme =
        sharedPreferences.getBool(PreferencesKey.currentDarkTheme) ?? false;
    final actionListDisplayMode = ObservableList<ActionListDisplayMode>();
    actionListDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(PreferencesKey.displayActionListModeKey) ??
            defaultActionsMode));
    final pinLength =
        sharedPreferences.getInt(PreferencesKey.currentPinLength) ??
            defaultPinLength;
    final savedLanguageCode =
        sharedPreferences.getString(PreferencesKey.currentLanguageCode) ??
            await Language.localeDetection();
    final initialCurrentLocale = await Devicelocale.currentLocale;
    final nodeId = sharedPreferences.getInt(PreferencesKey.currentNodeIdKey);
    final bitcoinElectrumServerId = sharedPreferences
        .getInt(PreferencesKey.currentBitcoinElectrumSererIdKey);
    final moneroNode = nodeSource.get(nodeId);
    final bitcoinElectrumServer = nodeSource.get(bitcoinElectrumServerId);
    final packageInfo = await PackageInfo.fromPlatform();

    return SettingsStore(
        sharedPreferences: sharedPreferences,
        nodes: {
          WalletType.monero: moneroNode,
          WalletType.bitcoin: bitcoinElectrumServer
        },
        nodeSource: nodeSource,
        appVersion: packageInfo.version,
        initialFiatCurrency: currentFiatCurrency,
        initialTransactionPriority: currentTransactionPriority,
        initialBalanceDisplayMode: currentBalanceDisplayMode,
        initialSaveRecipientAddress: shouldSaveRecipientAddress,
        initialAllowBiometricalAuthentication: allowBiometricalAuthentication,
        initialDarkTheme: savedDarkTheme,
        actionlistDisplayMode: actionListDisplayMode,
        initialPinLength: pinLength,
        initialLanguageCode: savedLanguageCode,
        initialCurrentLocale: initialCurrentLocale);
  }

  Future<void> setCurrentNode(Node node, WalletType walletType) async {
    switch (walletType) {
      case WalletType.bitcoin:
        await _sharedPreferences.setInt(
            PreferencesKey.currentBitcoinElectrumSererIdKey, node.key as int);
        break;
      case WalletType.monero:
        await _sharedPreferences.setInt(
            PreferencesKey.currentNodeIdKey, node.key as int);
        break;
      default:
        break;
    }

    nodes[walletType] = node;
  }
}
