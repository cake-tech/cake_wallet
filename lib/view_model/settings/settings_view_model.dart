import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/pin_code_required_duration.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info/package_info.dart';
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
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/themes/theme_base.dart';

part 'settings_view_model.g.dart';

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

List<TransactionPriority> priorityForWalletType(WalletType type) {
  switch (type) {
    case WalletType.monero:
      return monero!.getTransactionPriorities();
    case WalletType.bitcoin:
      return bitcoin!.getTransactionPriorities();
    case WalletType.litecoin:
      return bitcoin!.getLitecoinTransactionPriorities();
    case WalletType.haven:
      return haven!.getTransactionPriorities();
    default:
      return [];
  }
}

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(
      this._settingsStore,
      this._yatStore,
      this._authService,
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet)
      : itemHeaders = {},
        walletType = wallet.type,
        _wallet = wallet,
        _biometricAuth = BiometricAuth(),
        currentVersion = '' {
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

  }

  @observable
  String currentVersion;

  @computed
  Node get node => _settingsStore.getCurrentNode(walletType);

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  @computed
  PinCodeRequiredDuration get pinCodeRequiredDuration =>
    _settingsStore.pinTimeOutDuration;

  @computed
  String get languageCode => _settingsStore.languageCode;

  @computed
  ObservableList<ActionListDisplayMode> get actionlistDisplayMode =>
      _settingsStore.actionlistDisplayMode;

  @computed
  TransactionPriority get transactionPriority {
    final priority = _settingsStore.priority[walletType];

    if (priority == null) {
      throw Exception('Unexpected type ${walletType.toString()}');
    }

    return priority;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode =>
      _settingsStore.balanceDisplayMode;

  @computed
  bool get shouldDisplayBalance => balanceDisplayMode == BalanceDisplayMode.displayableBalance;

  @computed
  bool get shouldSaveRecipientAddress =>
      _settingsStore.shouldSaveRecipientAddress;

  @computed
  bool get allowBiometricalAuthentication =>
      _settingsStore.allowBiometricalAuthentication;

  @computed
  ThemeBase get theme => _settingsStore.currentTheme;

  bool get isBitcoinBuyEnabled => _settingsStore.isBitcoinBuyEnabled;

  final Map<String, String> itemHeaders;
  final SettingsStore _settingsStore;
  final YatStore _yatStore;
  final AuthService _authService;
  final WalletType walletType;
  final BiometricAuth _biometricAuth;
  final  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo> _wallet;

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

  @action
  Future<bool> biometricAuthenticated()async{
   return await _biometricAuth.canCheckBiometrics() && await _biometricAuth.isAuthenticated();
  }

  @action
  void onLanguageSelected (String code) {
    _settingsStore.languageCode = code;
  }

  @action
  void setTheme(ThemeBase newTheme){
     _settingsStore.currentTheme = newTheme;
  }

  @action
  void setShouldDisplayBalance(bool value){
  if (value) {
    _settingsStore.balanceDisplayMode = BalanceDisplayMode.displayableBalance;
    } else {
    _settingsStore.balanceDisplayMode = BalanceDisplayMode.hiddenBalance;
    }
  }

  @action
  setPinCodeRequiredDuration(PinCodeRequiredDuration duration) =>
      _settingsStore.pinTimeOutDuration = duration;

  String getDisplayPriority(dynamic priority) {
    final _priority = priority as TransactionPriority;

    if (_wallet.type == WalletType.bitcoin
        || _wallet.type == WalletType.litecoin) {
      final rate = bitcoin!.getFeeRate(_wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  void onDisplayPrioritySelected(TransactionPriority priority) =>
    _settingsStore.priority[_wallet.type] = priority;

  bool checkPinCodeRiquired() => _authService.requireAuth();

}
