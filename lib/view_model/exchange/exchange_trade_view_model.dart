import 'dart:async';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase(
      {required this.wallet,
      required this.trades,
      required this.tradesStore,
      required this.sendViewModel})
      : trade = tradesStore.trade!,
        isSendable = _checkIfCanSend(tradesStore, wallet),
        items = ObservableList<ExchangeTradeItem>() {
    switch (trade.provider) {
      case ExchangeProviderDescription.changeNow:
        _provider =
            ChangeNowExchangeProvider(settingsStore: sendViewModel.balanceViewModel.settingsStore);
        break;
      case ExchangeProviderDescription.sideShift:
        _provider = SideShiftExchangeProvider();
        break;
      case ExchangeProviderDescription.simpleSwap:
        _provider = SimpleSwapExchangeProvider();
        break;
      case ExchangeProviderDescription.trocador:
        _provider = TrocadorExchangeProvider();
        break;
      case ExchangeProviderDescription.exolix:
        _provider = ExolixExchangeProvider();
        break;
    }

    _updateItems();

    if (_provider != null) {
      _updateTrade();
      timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
    }
  }

  final WalletBase wallet;
  final Box<Trade> trades;
  final TradesStore tradesStore;
  final SendViewModel sendViewModel;

  @observable
  Trade trade;

  @observable
  bool isSendable;

  @computed
  String get extraInfo => trade.from == CryptoCurrency.xlm
      ? '\n\n' + S.current.xlm_extra_info
      : trade.from == CryptoCurrency.xrp
          ? '\n\n' + S.current.xrp_extra_info
          : '';

  @computed
  String get pendingTransactionFiatAmountValueFormatted => sendViewModel.isFiatDisabled
      ? ''
      : sendViewModel.pendingTransactionFiatAmount + ' ' + sendViewModel.fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted => sendViewModel.isFiatDisabled
      ? ''
      : sendViewModel.pendingTransactionFeeFiatAmount + ' ' + sendViewModel.fiat.title;

  @observable
  ObservableList<ExchangeTradeItem> items;

  ExchangeProvider? _provider;

  Timer? timer;

  @action
  Future<void> confirmSending() async {
    if (!isSendable) return;

    sendViewModel.clearOutputs();
    final output = sendViewModel.outputs.first;
    output.address = trade.inputAddress ?? '';
    output.setCryptoAmount(trade.amount);
    sendViewModel.selectedCryptoCurrency = trade.from;
    await sendViewModel.createTransaction();
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null)
        updatedTrade.createdAt = trade.createdAt;

      if (updatedTrade.amount.isEmpty) updatedTrade.amount = trade.amount;

      trade = updatedTrade;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final tagFrom =
        tradesStore.trade!.from.tag != null ? '${tradesStore.trade!.from.tag}' + ' ' : '';
    final tagTo = tradesStore.trade!.to.tag != null ? '${tradesStore.trade!.to.tag}' + ' ' : '';
    items.clear();
    items.add(ExchangeTradeItem(
        title: "${trade.provider.title} ${S.current.id}", data: '${trade.id}', isCopied: true));

    if (trade.extraId != null) {
      final title = trade.from == CryptoCurrency.xrp
          ? S.current.destination_tag
          : trade.from == CryptoCurrency.xlm
              ? S.current.memo
              : S.current.extra_id;

      items.add(ExchangeTradeItem(title: title, data: '${trade.extraId}', isCopied: false));
    }

    items.addAll([
      ExchangeTradeItem(title: S.current.amount, data: '${trade.amount}', isCopied: true),
      ExchangeTradeItem(
          title: S.current.send_to_this_address('${tradesStore.trade!.from}', tagFrom) + ':',
          data: trade.inputAddress ?? '',
          isCopied: true),
      ExchangeTradeItem(
          title: S.current.arrive_in_this_address('${tradesStore.trade!.to}', tagTo) + ':',
          data: trade.payoutAddress ?? '',
          isCopied: true),
    ]);
  }

  static bool _checkIfCanSend(TradesStore tradesStore, WalletBase wallet) {
    bool _isEthToken() =>
        wallet.currency == CryptoCurrency.eth &&
        tradesStore.trade!.from.tag == CryptoCurrency.eth.title;

    bool _isPolygonToken() =>
        wallet.currency == CryptoCurrency.maticpoly &&
        tradesStore.trade!.from.tag == CryptoCurrency.maticpoly.tag;

    bool _isSplToken() =>
        wallet.currency == CryptoCurrency.sol &&
        tradesStore.trade!.from.tag == CryptoCurrency.sol.title;

    return tradesStore.trade!.from == wallet.currency ||
        tradesStore.trade!.provider == ExchangeProviderDescription.xmrto ||
        _isEthToken() ||
        _isPolygonToken() ||
        _isSplToken();
  }
}
