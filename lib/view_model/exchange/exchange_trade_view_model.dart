import 'dart:async';

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
    sendViewModel.selectedCryptoCurrency = trade.from;
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
    final tagFrom =
        tradesStore.trade!.from.tag != null ? '${tradesStore.trade!.from.tag}' + ' ' : '';
    final tagTo = tradesStore.trade!.to.tag != null ? '${tradesStore.trade!.to.tag}' + ' ' : '';
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

    items.addAll([
      ExchangeTradeItem(
        title: S.current.amount,
        data: '${trade.amount} ${trade.from}',
        isCopied: false,
        isReceiveDetail: false,
        isExternalSendDetail: true,
      ),
      ExchangeTradeItem(
        title: S.current.you_will_receive_estimated_amount + ':',
        data: '${tradesStore.trade?.receiveAmount} ${trade.to}',
        isCopied: true,
        isReceiveDetail: true,
        isExternalSendDetail: false,
      ),
      ExchangeTradeItem(
        title: S.current.send_to_this_address('${tradesStore.trade!.from}', tagFrom) + ':',
        data: trade.inputAddress ?? '',
        isCopied: false,
        isReceiveDetail: false,
        isExternalSendDetail: true,
      ),
    ]);

    final isExtraIdExist = trade.extraId != null && trade.extraId!.isNotEmpty;

    if (isExtraIdExist) {
        final title = trade.from == CryptoCurrency.xrp
            ? S.current.destination_tag
            : trade.from == CryptoCurrency.xlm || trade.from == CryptoCurrency.ton
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
        title: S.current.arrive_in_this_address('${tradesStore.trade!.to}', tagTo) + ':',
        data: trade.payoutAddress ?? '',
        isCopied: true,
        isReceiveDetail: true,
        isExternalSendDetail: false,
      ),
    );
  }

  static bool _checkIfCanSend(TradesStore tradesStore, WalletBase wallet) {
    bool _isEthToken() =>
        wallet.currency == CryptoCurrency.eth &&
        tradesStore.trade!.from.tag == CryptoCurrency.eth.title;

    bool _isPolygonToken() =>
        wallet.currency == CryptoCurrency.maticpoly &&
        tradesStore.trade!.from.tag == CryptoCurrency.maticpoly.tag;

    bool _isTronToken() =>
        wallet.currency == CryptoCurrency.trx &&
        tradesStore.trade!.from.tag == CryptoCurrency.trx.title;

    bool _isSplToken() =>
        wallet.currency == CryptoCurrency.sol &&
        tradesStore.trade!.from.tag == CryptoCurrency.sol.title;

    return tradesStore.trade!.from == wallet.currency ||
        tradesStore.trade!.provider == ExchangeProviderDescription.xmrto ||
        _isEthToken() ||
        _isPolygonToken() ||
        _isSplToken() ||
        _isTronToken();
  }
}
