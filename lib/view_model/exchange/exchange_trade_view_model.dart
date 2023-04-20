import 'dart:async';
import 'package:cake_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/simpleswap/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trocador/trocador_exchange_provider.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase(
      {required this.wallet,
      required this.trades,
      required this.tradesStore,
      required this.sendViewModel})
      : trade = tradesStore.trade!,
        isSendable = tradesStore.trade!.from == wallet.currency ||
            tradesStore.trade!.provider == ExchangeProviderDescription.xmrto,
        items = ObservableList<ExchangeTradeItem>() {
    switch (trade.provider) {
      case ExchangeProviderDescription.xmrto:
        _provider = XMRTOExchangeProvider();
        break;
      case ExchangeProviderDescription.changeNow:
        _provider = ChangeNowExchangeProvider();
        break;
      case ExchangeProviderDescription.morphToken:
        _provider = MorphTokenExchangeProvider(trades: trades);
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
    }

    _updateItems();
    _updateTrade();
    timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
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
  Future confirmSending() async {
    if (!isSendable) {
      return;
    }

    sendViewModel.clearOutputs();
    final output = sendViewModel.outputs.first;
    output.address = trade.inputAddress ?? '';
    output.setCryptoAmount(trade.amount);
    await sendViewModel.createTransaction();
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null) {
        updatedTrade.createdAt = trade.createdAt;
      }

      trade = updatedTrade;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final tagFrom = trade.from.tag != null ? '${trade.from.tag}' + ' ' : '';
    final tagTo = trade.to.tag != null ? '${trade.to.tag}' + ' ' : '';
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
          title: S.current.send_to_this_address('${trade.from}', tagFrom) + ':',
          data: trade.inputAddress ?? '',
          isCopied: true),
      ExchangeTradeItem(
          title: S.current.arrive_in_this_address('${trade.to}', tagTo) + ':',
          data: trade.payoutAddress ?? '',
          isCopied: true),
    ]);
  }
}
