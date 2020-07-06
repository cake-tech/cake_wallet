import 'package:cake_wallet/di.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/common/language.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_display_mode.dart';

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
      @required this.node,
      @required this.appVersion,
      this.actionlistDisplayMode}) {
    fiatCurrency = initialFiatCurrency;
    transactionPriority = initialTransactionPriority;
    balanceDisplayMode = initialBalanceDisplayMode;
    shouldSaveRecipientAddress = initialSaveRecipientAddress;
    allowBiometricalAuthentication = initialAllowBiometricalAuthentication;
    isDarkTheme = initialDarkTheme;
    defaultPinLength = initialPinLength;
    languageCode = initialLanguageCode;
    currentLocale = initialCurrentLocale;
    itemHeaders = {};

//    actionlistDisplayMode.observe(
//        (dynamic _) => _sharedPreferences.setInt(displayActionListModeKey,
//            serializeActionlistDisplayModes(actionlistDisplayMode)),
//        fireImmediately: false);

    _sharedPreferences = sharedPreferences;
    _nodeSource = nodeSource;
  }

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

  @observable
  Map<String, String> itemHeaders;

  String languageCode;

  String currentLocale;

  String appVersion;

  SharedPreferences _sharedPreferences;
  Box<Node> _nodeSource;

  static Future<SettingsStore> load(
      {@required Box<Node> nodeSource,
      FiatCurrency initialFiatCurrency = FiatCurrency.usd,
      TransactionPriority initialTransactionPriority = TransactionPriority.slow,
      BalanceDisplayMode initialBalanceDisplayMode =
          BalanceDisplayMode.availableBalance}) async {
    final sharedPreferences = await getIt.getAsync<SharedPreferences>();
    final currentFiatCurrency = FiatCurrency(
        symbol: sharedPreferences.getString(currentFiatCurrencyKey));
    final currentTransactionPriority = TransactionPriority.deserialize(
        raw: sharedPreferences.getInt(currentTransactionPriorityKey));
    final currentBalanceDisplayMode = BalanceDisplayMode.deserialize(
        raw: sharedPreferences.getInt(currentBalanceDisplayModeKey));
    final shouldSaveRecipientAddress =
        sharedPreferences.getBool(shouldSaveRecipientAddressKey);
    final allowBiometricalAuthentication =
        sharedPreferences.getBool(allowBiometricalAuthenticationKey) ?? false;
    final savedDarkTheme = sharedPreferences.getBool(currentDarkTheme) ?? false;
    final actionListDisplayMode = ObservableList<ActionListDisplayMode>();
    actionListDisplayMode.addAll(deserializeActionlistDisplayModes(
        sharedPreferences.getInt(displayActionListModeKey) ??
            11)); // FIXME: Unnamed constant.
    final defaultPinLength = sharedPreferences.getInt(currentPinLength) ??
        4; // FIXME: Unnamed constant.
    final savedLanguageCode =
        sharedPreferences.getString(currentLanguageCode) ??
            await Language.localeDetection();
    final initialCurrentLocale = await Devicelocale.currentLocale;
    final nodeId = sharedPreferences.getInt(currentNodeIdKey);
    final node = nodeSource.get(nodeId);
    final packageInfo = await PackageInfo.fromPlatform();

    return SettingsStore(
        sharedPreferences: sharedPreferences,
        node: node,
        nodeSource: nodeSource,
        appVersion: packageInfo.version,
        initialFiatCurrency: currentFiatCurrency,
        initialTransactionPriority: currentTransactionPriority,
        initialBalanceDisplayMode: currentBalanceDisplayMode,
        initialSaveRecipientAddress: shouldSaveRecipientAddress,
        initialAllowBiometricalAuthentication: allowBiometricalAuthentication,
        initialDarkTheme: savedDarkTheme,
        actionlistDisplayMode: actionListDisplayMode,
        initialPinLength: defaultPinLength,
        initialLanguageCode: savedLanguageCode,
        initialCurrentLocale: initialCurrentLocale);
  }
}
