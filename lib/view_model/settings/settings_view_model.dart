import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/action_list_display_mode.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cake_wallet/themes/theme_base.dart';

part 'settings_view_model.g.dart';

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(
      this._settingsStore,
      this._yatStore,
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet)
      : itemHeaders = {},
        walletType = wallet.type,
        _wallet = wallet{
  
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

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

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
  ThemeBase get theme => _settingsStore.currentTheme;

  bool get isBitcoinBuyEnabled => _settingsStore.isBitcoinBuyEnabled;

  final Map<String, String> itemHeaders;
  final SettingsStore _settingsStore;
  final YatStore _yatStore;
  final WalletType walletType;
  final  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo> _wallet;

  @action
  void setFiatCurrency(FiatCurrency value) =>
      _settingsStore.fiatCurrency = value;

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
