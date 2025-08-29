import 'dart:async';

import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase({
    required this.wallet,
    required this.trades,
    required this.tradesStore,
    required this.sendViewModel,
    required this.feesViewModel,
    required this.fiatConversionStore,
  })  : trade = tradesStore.trade!,
        isSendable = _checkIfCanSend(tradesStore, wallet),
        items = ObservableList<ExchangeTradeItem>() {
    setUpOutput();
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
      case ExchangeProviderDescription.swapTrade:
        _provider = SwapTradeExchangeProvider();
        break;
      case ExchangeProviderDescription.stealthEx:
        _provider = StealthExExchangeProvider();
        break;
      case ExchangeProviderDescription.thorChain:
        _provider = ThorChainExchangeProvider(tradesStore: trades);
        break;
      case ExchangeProviderDescription.chainflip:
        _provider = ChainflipExchangeProvider(tradesStore: trades);
        break;
      case ExchangeProviderDescription.xoSwap:
        _provider = XOSwapExchangeProvider();
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
  final FeesViewModel feesViewModel;

  late Output output;

  @observable
  Trade trade;

  @observable
  bool isSendable;

  String get extraInfo => trade.extraId != null && trade.extraId!.isNotEmpty
      ? '\n\n' + S.current.exchange_extra_info
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

  final FiatConversionStore fiatConversionStore;

  FiatCurrency get fiat => sendViewModel.fiat;

  @computed
  bool get isFiatDisabled => feesViewModel.isFiatDisabled;

  @computed
  String get receiveAmountFiatFormatted {
    var amount = '0.00';
    try {
      if (trade.receiveAmount?.isNotEmpty ?? false) {
        if (fiatConversionStore.prices[trade.to] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[trade.to]!,
          cryptoAmount: trade.receiveAmount,
        );
      }
    } catch (_) {
      printV('Error calculating receive amount fiat formatted: $_');
    }
    return isFiatDisabled ? '' : '$amount ${fiat.title}';
  }

  @computed
  String get sendAmountFiatFormatted {
    var amount = '0.00';
    try {
      if (trade.amount.isNotEmpty) {
        if (fiatConversionStore.prices[trade.from] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[trade.from]!,
          cryptoAmount: trade.amount,
        );
      }
    } catch (_) {
      printV('Error calculating send amount fiat formatted: $_');
    }
    return isFiatDisabled ? '' : '$amount ${fiat.title}';
  }

  void setUpOutput() {
    sendViewModel.clearOutputs();
    output = sendViewModel.outputs.first;
    output.address = trade.inputAddress ?? '';
    output.setCryptoAmount(trade.amount);
    if (_provider is ThorChainExchangeProvider) output.memo = trade.memo;
    if (trade.isSendAll == true) output.sendAll = true;
  }

  @action
  Future<void> confirmSending() async {
    if (!isSendable) return;

    final selected = trade.from ?? trade.userCurrencyFrom;
    if (selected == null) {
      printV('No selectable currency for trade ${trade.id}');
      return;
    }

    sendViewModel.selectedCryptoCurrency = selected;

    final pendingTransaction = await sendViewModel.createTransaction(provider: _provider);
    if (_provider is ThorChainExchangeProvider) {
      trade.id = pendingTransaction?.id ?? '';
      trades.add(trade);
    }
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final agreedAmount = tradesStore.trade!.amount;
      final isSendAll = tradesStore.trade!.isSendAll;
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null)
        updatedTrade.createdAt = trade.createdAt;

      if (updatedTrade.amount.isEmpty) updatedTrade.amount = trade.amount;

      trade = updatedTrade;
      trade.amount = agreedAmount;
      trade.isSendAll = isSendAll;

      _updateItems();
    } catch (e) {
      printV(e.toString());
    }
  }

  void _updateItems() {
    final trade = tradesStore.trade!;
    final tradeFrom = trade.fromRaw >= 0 ? trade.from : trade.userCurrencyFrom;

    final tradeTo = trade.toRaw >= 0 ? trade.to : trade.userCurrencyTo;

    final tagFrom = tradeFrom?.tag != null ? '${tradeFrom!.tag}' + ' ' : '';
    final tagTo = tradeTo?.tag != null ? '${tradeTo!.tag}' + ' ' : '';

    items.clear();

    if (trade.provider != ExchangeProviderDescription.thorChain)
      items.add(
        ExchangeTradeItem(
          title: "${trade.provider.title} ${S.current.id}",
          data: '${trade.id}',
          isCopied: true,
          isReceiveDetail: true,
          isExternalSendDetail: false,
        ),
      );

    if (tradeFrom != null || tradeTo != null) {
      items.addAll([
        ExchangeTradeItem(
          title: S.current.amount,
          data: '${trade.amount} ${tradeFrom}',
          isCopied: false,
          isReceiveDetail: false,
          isExternalSendDetail: true,
        ),
        ExchangeTradeItem(
          title: S.current.you_will_receive_estimated_amount + ':',
          data: '${tradesStore.trade?.receiveAmount} ${tradeTo}',
          isCopied: true,
          isReceiveDetail: true,
          isExternalSendDetail: false,
        ),
        ExchangeTradeItem(
          title: S.current.send_to_this_address('${tradeFrom}', tagFrom) + ':',
          data: trade.inputAddress ?? '',
          isCopied: false,
          isReceiveDetail: false,
          isExternalSendDetail: true,
        ),
      ]);
    }

    final isExtraIdExist = trade.extraId != null && trade.extraId!.isNotEmpty;

    if (isExtraIdExist) {
      final title = tradeFrom == CryptoCurrency.xrp
          ? S.current.destination_tag
          : tradeFrom == CryptoCurrency.xlm || tradeFrom == CryptoCurrency.ton
              ? S.current.memo
              : S.current.extra_id;

      items.add(
        ExchangeTradeItem(
            title: title,
            data: trade.extraId ?? '',
            isCopied: true,
            isReceiveDetail: !isExtraIdExist,
            isExternalSendDetail: isExtraIdExist),
      );
    }

    items.add(
      ExchangeTradeItem(
        title: S.current.arrive_in_this_address('${tradeTo}', tagTo) + ':',
        data: trade.payoutAddress ?? '',
        isCopied: true,
        isReceiveDetail: true,
        isExternalSendDetail: false,
      ),
    );
  }

  static bool _checkIfCanSend(TradesStore tradesStore, WalletBase wallet) {
    final trade = tradesStore.trade!;
    final tradeFrom = trade.fromRaw >= 0 ? trade.from : trade.userCurrencyFrom;

    bool _isEthToken() =>
        wallet.currency == CryptoCurrency.eth && tradeFrom?.tag == CryptoCurrency.eth.title;

    bool _isPolygonToken() =>
        wallet.currency == CryptoCurrency.maticpoly &&
        tradeFrom?.tag == CryptoCurrency.maticpoly.tag;

    bool _isTronToken() =>
        wallet.currency == CryptoCurrency.trx && tradeFrom?.tag == CryptoCurrency.trx.title;

    bool _isSplToken() =>
        wallet.currency == CryptoCurrency.sol && tradeFrom?.tag == CryptoCurrency.sol.title;

    return tradeFrom == wallet.currency ||
        tradesStore.trade!.provider == ExchangeProviderDescription.xmrto ||
        _isEthToken() ||
        _isPolygonToken() ||
        _isSplToken() ||
        _isTronToken();
  }
}
