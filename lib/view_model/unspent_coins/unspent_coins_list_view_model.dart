import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase({
    required this.wallet,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    this.coinTypeToSpendFrom = UnspentCoinType.any,
    required FiatConversionStore fiatConversationStore,
    required SettingsStore settingsStore,
  })  : _unspentCoinsInfo = unspentCoinsInfo,
        _fiatConversationStore = fiatConversationStore,
        _settingsStore = settingsStore,
        items = ObservableList<UnspentCoinsItem>(),
        _originalState = {};

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;
  final Box<UnspentCoinsInfo> _unspentCoinsInfo;
  final FiatConversionStore _fiatConversationStore;
  final SettingsStore _settingsStore;
  final UnspentCoinType coinTypeToSpendFrom;

  @observable
  ObservableList<UnspentCoinsItem> items;

  final Map<String, Map<String, dynamic>> _originalState;

  @observable
  bool isDisposing = false;

  @observable
  bool isSavingItems = false;

  @computed
  bool get isAllSelected => items.every((element) => element.isFrozen || element.isSending);

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  @computed
  bool get isFiatDisabled => _settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  Map<String, String> get fiatAmounts {

    final currency = wallet.currency;
    final price = _fiatConversationStore.prices[currency];
    if (price == null || price == 0.0 || isFiatDisabled) return {};

    final result = <String, String>{};
    for (final item in items) {
      final formatted = formatAmountToString(item.value);
      final cryptoAmount = double.tryParse(formatted.replaceAll(',', '')) ?? 0.0;
      final fiatValue = price * cryptoAmount;
      result[item.hash] = fiatCurrency.title + ' ' + fiatValue.toStringAsFixed(2);
    }

    return result;
  }

  Future<void> initialSetup() async {
    await _updateUnspents();
    _storeOriginalState();
  }

  void _storeOriginalState() {
    _originalState.clear();
    for (final item in items) {
      _originalState[item.hash] = {
        'isFrozen': item.isFrozen,
        'note': item.note,
        'isSending': item.isSending,
      };
    }
  }

  bool _hasAdjustableFieldChanged(UnspentCoinsItem item) {
    final original = _originalState[item.hash];
    if (original == null) return false;
    return original['isFrozen'] != item.isFrozen ||
        original['note'] != item.note ||
        original['isSending'] != item.isSending;
  }

  bool get hasAdjustableFieldChanged => items.any(_hasAdjustableFieldChanged);

  Future<void> saveUnspentCoinInfo(UnspentCoinsItem item) async {
    try {
      item.isBeingSaved = true;
      isSavingItems = true;
      final existingInfo = _unspentCoinsInfo.values
          .firstWhereOrNull((element) => element.walletId == wallet.id && element == item);
      if (existingInfo == null) return;

      existingInfo.isFrozen = item.isFrozen;
      existingInfo.isSending = item.isSending;
      existingInfo.note = item.note;

      await existingInfo.save().then((value){
        item.isBeingSaved = false;
        isSavingItems = false;
      });
      _updateUnspentCoinsInfo();
    } catch (e) {
      printV('Error saving coin info: $e');
      item.isBeingSaved = false;
      isSavingItems = false;
    }
  }

  String formatAmountToString(int fullBalance) {
    if (wallet.type == WalletType.monero)
      return monero!.formatterMoneroAmountToString(amount: fullBalance);
    if (wallet.type == WalletType.wownero)
      return wownero!.formatterWowneroAmountToString(amount: fullBalance);
    if ([WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash, WalletType.dogecoin].contains(wallet.type))
      return bitcoin!.formatterBitcoinAmountToString(amount: fullBalance);
    if (wallet.type == WalletType.decred)
      return decred!.formatterDecredAmountToString(amount: fullBalance);
    return '';
  }

  Future<void> _updateUnspents() async {
    if (wallet.type == WalletType.monero) {
      await monero!.updateUnspents(wallet);
    }
    if (wallet.type == WalletType.wownero) {
      await wownero!.updateUnspents(wallet);
    }
    if ([WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash, WalletType.dogecoin].contains(wallet.type)) {
      await bitcoin!.updateUnspents(wallet);
    }
    if (wallet.type == WalletType.decred) {
      decred!.updateUnspents(wallet);
    }
    _updateUnspentCoinsInfo();
  }

  List<Unspent> _getUnspents() {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.getUnspents(wallet);
      case WalletType.wownero:
        return wownero!.getUnspents(wallet);
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
        return bitcoin!.getUnspents(wallet, coinTypeToSpendFrom: coinTypeToSpendFrom);
      case WalletType.decred:
        return decred!.getUnspents(wallet);
      default:
        return List.empty();
    }
  }

    List<Unspent> _getSpecificUnspents(UnspentCoinType overrideCoinTypeToSpendFrom) {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.getUnspents(wallet);
      case WalletType.wownero:
        return wownero!.getUnspents(wallet);
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
      case WalletType.dogecoin:
        return bitcoin!.getUnspents(wallet, coinTypeToSpendFrom: overrideCoinTypeToSpendFrom);
      case WalletType.decred:
        return decred!.getUnspents(wallet);
      default:
        return List.empty();
    }
  }

  @action
  Future<int> getSendingBalance(UnspentCoinType overrideCoinTypeToSpendFrom) async {
    // return items.where((element) => element.isSending).fold(0, (previousValue, element) => previousValue + element.value);
    // go through all unspent coins and add up the value minus frozen and non sending:
    int total = 0;
    await _updateUnspents();
    Set<String> seen = {};
    for (final item in _getSpecificUnspents(overrideCoinTypeToSpendFrom)) {
      if (seen.contains(item.toString())) continue;
      seen.add(item.toString());
      if (item.isFrozen || !item.isSending) continue;
      total += item.value;
    }
    return total;
  }

  @action
  void _updateUnspentCoinsInfo() {
    final unspents = _getUnspents()
        .map((elem) {
          try {
            final existingItem = _unspentCoinsInfo.values
                .firstWhereOrNull((item) => item.walletId == wallet.id && item == elem);;

            if (existingItem == null) return null;

            return UnspentCoinsItem(
              address: elem.address,
              amount: '${formatAmountToString(elem.value)} ${wallet.currency.title}',
              hash: elem.hash,
              isFrozen: existingItem.isFrozen,
              note: existingItem.note,
              isSending: existingItem.isSending,
              value: elem.value,
              vout: elem.vout,
              keyImage: elem.keyImage,
              isChange: elem.isChange,
              isSilentPayment: existingItem.isSilentPayment ?? false,
            );
          } catch (e, s) {
            printV('Error: $e\nStack: $s');
            ExceptionHandler.onError(
              FlutterErrorDetails(exception: e, stack: s),
            );
            return null;
          }
        })
        .whereType<UnspentCoinsItem>()
        .toList();

    unspents.sort((a, b) => b.value.compareTo(a.value));
    items.clear();
    items.addAll(unspents);
  }

  @action
  void resetUnspentCoinsInfoSelections() {
    // reset all unspent coins selections to true except frozen ones
    for (final item in items) {
      if (!item.isFrozen) {
        item.isSending = true;
        saveUnspentCoinInfo(item);
      }
    }
  }

  @action
  void toggleSelectAll(bool value) {
    for (final item in items) {
      if (item.isFrozen || item.isSending == value) continue;
      item.isSending = value;
      saveUnspentCoinInfo(item);
    }
  }

  @action
  void setIsDisposing(bool value) => isDisposing = value;

  @action
  void updateWallet(WalletBase newWallet) {
    wallet = newWallet;
  }

  @action
  Future<void> dispose() async {
    await _updateUnspents();
    await wallet.updateBalance();
  }
}
