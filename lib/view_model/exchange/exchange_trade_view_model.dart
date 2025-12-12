import 'dart:async';

import 'package:cake_wallet/core/payment_uris.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_item.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/utils/qr_util.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
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
        break;
      case ExchangeProviderDescription.swapsXyz:
        _provider = SwapsXyzExchangeProvider();
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
  final FeesViewModel feesViewModel;

  late Output output;

  @observable
  Trade trade;

  @observable
  bool isSendable;

  bool get isSwapsXyzSendingEVMTokenSwap =>
      (_provider is SwapsXyzExchangeProvider) &&
      isEVMCompatibleChain(wallet.type) &&
      wallet.currency != trade.from;

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

  @action
  String getReceiveAmountFiatFormatted(String receiveAmount) {
    var amount = '0.00';
    try {
      if (receiveAmount.isNotEmpty) {
        if (fiatConversionStore.prices[trade.to] == null) return '';

        amount = calculateFiatAmount(
          price: fiatConversionStore.prices[trade.to]!,
          cryptoAmount: receiveAmount,
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

    final pendingTransaction =
        await sendViewModel.createTransaction(provider: _provider, trade: trade);

    if (_provider is SwapsXyzExchangeProvider) {
      final hash = pendingTransaction?.evmTxHashFromRawHex ?? pendingTransaction?.id ?? '';
      trade.txId = hash;

      if (trade.isInBox) {
        await trade.save();
      } else {
        await trades.add(trade);
      }
    }

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

    bool _isBaseToken() =>
        wallet.currency == CryptoCurrency.baseEth && tradeFrom?.tag == CryptoCurrency.baseEth.tag;

    bool _isArbitrumToken() =>
        wallet.currency == CryptoCurrency.arbEth && tradeFrom?.tag == CryptoCurrency.arbEth.tag;

    bool _isTronToken() =>
        wallet.currency == CryptoCurrency.trx && tradeFrom?.tag == CryptoCurrency.trx.title;

    bool _isSplToken() =>
        wallet.currency == CryptoCurrency.sol && tradeFrom?.tag == CryptoCurrency.sol.title;

    return tradeFrom == wallet.currency ||
        tradesStore.trade!.provider == ExchangeProviderDescription.xmrto ||
        _isEthToken() ||
        _isPolygonToken() ||
        _isSplToken() ||
        _isTronToken() ||
        _isBaseToken() ||
        _isArbitrumToken();
  }

  Future<void> registerSwapsXyzTransaction() async {
    try {
      if (!(_provider is SwapsXyzExchangeProvider)) return;
      final swaps = _provider as SwapsXyzExchangeProvider;

      // register only for vmId is alt-vm or bridgeId is alt-vm (trade.needToRegisterInSwapXyz)
      final needToRegister = trade.needToRegisterInSwapXyz ?? false;
      if (!needToRegister) return;

      final vmId = (trade.providerId ?? '').toLowerCase();
      if (vmId.isEmpty) {
        printV('SwapsXyz: transaction register: skipped (vmId empty)');
        return;
      }

      final txHash = sendViewModel.pendingTransaction?.evmTxHashFromRawHex ??
          sendViewModel.pendingTransaction?.id ??
          '';

      if (txHash.isEmpty) {
        printV('SwapsXyz: transaction register: skipped (txHash empty)');
        return;
      }

      final chainId = int.tryParse(trade.router ?? '') ?? 0;
      if (chainId <= 0) {
        printV('SwapsXyz: transaction register: skipped (invalid chainId)');
        return;
      }

      printV(
          'SwapsXyz: attempting to register transaction: tradeId = ${trade.id}, txHash = $txHash, chainId = $chainId, vmId = $vmId');

      final registered = await swaps.registerAltVmTx(
        txId: trade.id,
        txHash: txHash,
        chainId: chainId,
        vmId: vmId,
      );

      if (!registered) {
        printV('SwapsXyz: transaction register: failed');
      } else {
        printV('SwapsXyz: transaction register: success');
      }
    } catch (e) {
      printV('registerSwapsXyzTransaction error: $e');
    }
  }

  PaymentURI? get paymentUri {
    final inputAddress = trade.inputAddress;
    final amount = trade.amount;
    final fromCurrency = trade.from ?? trade.userCurrencyFrom;

    if (inputAddress == null || inputAddress.isEmpty || fromCurrency == null) {
      return null;
    }

    switch (wallet.type) {
      case WalletType.bitcoin:
        return BitcoinURI(amount: amount, address: inputAddress);
      case WalletType.litecoin:
        return LitecoinURI(amount: amount, address: inputAddress);
      case WalletType.bitcoinCash:
        return BitcoinCashURI(amount: amount, address: inputAddress);
      case WalletType.dogecoin:
        return DogeURI(amount: amount, address: inputAddress);
      case WalletType.ethereum:
        return _createERC681URI(fromCurrency, inputAddress, amount);
      // TODO: Expand ERC681URI support to Polygon(modify decoding flow for QRs, pay anything, and deep link handling)
      case WalletType.polygon:
        return PolygonURI(amount: amount, address: inputAddress);
      case WalletType.base:
        return BaseURI(amount: amount, address: inputAddress);
      case WalletType.arbitrum:
        return ArbitrumURI(amount: amount, address: inputAddress);
      case WalletType.solana:
        return SolanaURI(amount: amount, address: inputAddress);
      case WalletType.tron:
        return TronURI(amount: amount, address: inputAddress);
      case WalletType.monero:
        return MoneroURI(amount: amount, address: inputAddress);
      case WalletType.wownero:
        return WowneroURI(amount: amount, address: inputAddress);
      case WalletType.zano:
        return ZanoURI(amount: amount, address: inputAddress);
      case WalletType.decred:
        return DecredURI(amount: amount, address: inputAddress);
      case WalletType.haven:
        return HavenURI(amount: amount, address: inputAddress);
      case WalletType.nano:
        return NanoURI(amount: amount, address: inputAddress);
      default:
        return null;
    }
  }

  @action
  PaymentURI? _createERC681URI(CryptoCurrency currency, String address, String amount) {
    final chainId = TokenUtilities.getChainId(currency);
    final isNativeToken = TokenUtilities.isNativeToken(currency);

    if (isNativeToken) {
      return ERC681URI(
        chainId: chainId,
        address: address,
        amount: amount,
        contractAddress: null,
      );
    } else {
      if (isEVMCompatibleChain(wallet.type)) {
        final erc20Token = TokenUtilities.findErc20Token(currency, wallet);

        if (erc20Token != null) {
          return ERC681URI(
            chainId: chainId,
            address: address,
            amount: amount,
            contractAddress: erc20Token.contractAddress,
          );
        }
      }
      return null;
    }
  }

  @computed
  String get qrImage => getQrImage(wallet.type);
}
