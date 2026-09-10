import 'dart:async';

import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/jupiter_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/near_Intents_exchange_provider.dart';
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
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
import 'package:cake_wallet/utils/qr_util.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'exchange_trade_view_model.g.dart';

class ExchangeTradeViewModel = ExchangeTradeViewModelBase with _$ExchangeTradeViewModel;

abstract class ExchangeTradeViewModelBase with Store {
  ExchangeTradeViewModelBase({
    required this.wallet,
    required this.tradesStore,
    required this.sendViewModel,
    required this.feesViewModel,
    required this.fiatConversionStore,
  })  : trade = tradesStore.trade!,
        isSwapsXYZCanSendFromExternal =
            _checkIfSwapsXYZCanSendFromExternal(tradesStore.trade!, wallet),
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
        _provider = ThorChainExchangeProvider();
        break;
      case ExchangeProviderDescription.chainflip:
        _provider = ChainflipExchangeProvider();
        break;
      case ExchangeProviderDescription.xoSwap:
        _provider = XOSwapExchangeProvider();
        break;
      case ExchangeProviderDescription.swapsXyz:
        _provider = SwapsXyzExchangeProvider();
        break;
      case ExchangeProviderDescription.jupiter:
        _provider = JupiterExchangeProvider();
        break;
      case ExchangeProviderDescription.nearIntents:
        _provider = NearIntentsExchangeProvider();
        break;
    }

    _updateItems();

    if (_provider != null) {
      _updateTrade();
      timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
    }
  }

  final WalletBase wallet;
  final TradesStore tradesStore;
  final SendViewModel sendViewModel;
  final FeesViewModel feesViewModel;

  late Output output;

  AmountParsingProxy get _amountParsingProxy => sendViewModel.amountParsingProxy;

  @observable
  Trade trade;

  bool isSwapsXYZCanSendFromExternal;

  bool get isSendable => checkIfCanSend(trade, wallet) == null;

  /// Providers that should hide the "send from external" button
  static const List<Type> _providersThatHideExternalSend = [
    JupiterExchangeProvider,
  ];

  /// Returns true if the current provider should hide the external send button
  bool get shouldHideExternalSendButton {
    if (_provider == null) return false;

    if (!isSwapsXYZCanSendFromExternal) return true;

    return _providersThatHideExternalSend.any(
      (providerType) => _provider.runtimeType == providerType,
    );
  }

  String get extraInfo => trade.extraId != null && trade.extraId!.isNotEmpty
      ? "\n\n${S.current.exchange_extra_info}"
      : "";

  @computed
  String get pendingTransactionFiatAmountValueFormatted => sendViewModel.isFiatDisabled
      ? ""
      : "${sendViewModel.pendingTransactionFiatAmount} ${sendViewModel.fiat.title}";

  @computed
  String get pendingTransactionFeeFiatAmountFormatted => sendViewModel.isFiatDisabled
      ? ""
      : "${sendViewModel.pendingTransactionFeeFiatAmount} ${sendViewModel.fiat.title}";

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
    if (_provider is ThorChainExchangeProvider) output.memo = trade.memo ?? "";
    if (trade.isSendAll == true) output.sendAll = true;
  }

  @action
  Future<void> confirmSending() async {
    final canSendError = checkIfCanSend(trade, wallet);

    if (canSendError != null) {
      _logCanSendError(trade, wallet, canSendError);
      sendViewModel.state = FailureState(canSendError);
      return;
    }

    final selected = trade.from;
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
      await trade.save();
    }

    if (_provider is ThorChainExchangeProvider) {
      trade.id = pendingTransaction?.id ?? '';
      await trade.save();
    }
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider!.findTradeById(id: trade.id);

      trade.mergeFindTradeByIdResult(updatedTrade);
      await trade.save();
      tradesStore.setTrade(trade);

      _updateItems();
    } catch (e) {
      printV(e.toString());
    }
  }

  void _updateItems() {
    final tradeFrom = trade.from;
    final tradeTo = trade.to;

    final tagFrom = tradeFrom?.tag != null ? "${tradeFrom!.tag} " : "";
    final tagTo = tradeTo?.tag != null ? "${tradeTo!.tag} " : "";

    items.clear();

    if (trade.provider != ExchangeProviderDescription.thorChain)
      items.add(
        ExchangeTradeItem(
          title: "${trade.provider.title} ${S.current.id}",
          data: "${trade.id}",
          isCopied: true,
          isReceiveDetail: true,
          isExternalSendDetail: false,
        ),
      );

    if (tradeFrom != null && tradeTo != null) {
      items.addAll([
        ExchangeTradeItem(
          title: S.current.amount,
          data:
              "${_amountParsingProxy.getDisplayCryptoAmount(trade.amount, tradeFrom)} ${_amountParsingProxy.getCryptoSymbol(tradeFrom)}",
          isCopied: false,
          isReceiveDetail: false,
          isExternalSendDetail: true,
        ),
        ExchangeTradeItem(
          title: "${S.current.you_will_receive_estimated_amount}:",
          data:
              "${_amountParsingProxy.getDisplayCryptoAmount(trade.receiveAmount ?? "0", tradeTo)} ${_amountParsingProxy.getCryptoSymbol(tradeTo)}",
          isCopied: true,
          isReceiveDetail: true,
          isExternalSendDetail: false,
        ),
        ExchangeTradeItem(
          title: "${S.current.send_to_this_address("$tradeFrom", tagFrom)}:",
          data: trade.inputAddress ?? '',
          isCopied: false,
          isReceiveDetail: false,
          isExternalSendDetail: true,
        ),
      ]);

      items.add(
        isSwapsXYZCanSendFromExternal
            ? ExchangeTradeItem(
                title: S.current.send_to_this_address('${tradeFrom}', tagFrom) + ':',
                data: trade.inputAddress ?? '',
                isCopied: false,
                isReceiveDetail: false,
                isExternalSendDetail: true)
            : ExchangeTradeItem(
                title: 'Smart contract call (no address required)',
                data: 'Wallet will execute a contract call. On-chain transaction',
                isCopied: false,
                isReceiveDetail: false,
                isExternalSendDetail: true),
      );
    }

    final isExtraIdExist = trade.extraId != null && trade.extraId!.isNotEmpty;

    if (isExtraIdExist) {
      final title = tradeFrom == CryptoCurrency.xrp
          ? S.current.destination_tag
          : [CryptoCurrency.xlm, CryptoCurrency.ton].contains(tradeFrom)
              ? S.current.memo
              : S.current.extra_id;

      items.add(
        ExchangeTradeItem(
          title: title,
          data: trade.extraId ?? "",
          isCopied: true,
          isReceiveDetail: !isExtraIdExist,
          isExternalSendDetail: isExtraIdExist,
        ),
      );
    }

    items.add(
      ExchangeTradeItem(
        title: "${S.current.arrive_in_this_address("${tradeTo}", tagTo)}:",
        data: trade.payoutAddress ?? "",
        isCopied: true,
        isReceiveDetail: true,
        isExternalSendDetail: false,
      ),
    );
  }

  String? checkIfCanSend(Trade? trade, WalletBase wallet) {
    if (trade == null) return 'Trade is null';

    final tradeFrom = trade.from;
    if (tradeFrom == null) return 'Trade from currency is null';

    bool _sameCurrency(CryptoCurrency a, CryptoCurrency b) => a.titleAndTagEqual(b);

    bool _isTokenBelongingToWallet(CryptoCurrency cur) {
      final chainTag = cur.tag ?? cur.title;
      return wallet.currency == cur &&
          (tradeFrom.tag?.toUpperCase() == chainTag.toUpperCase() ||
              tradeFrom.title.toUpperCase() == chainTag.toUpperCase());
    }

    final canSend = _sameCurrency(tradeFrom, wallet.currency) ||
        (_sameCurrency(tradeFrom, CryptoCurrency.btcln) && wallet.currency == CryptoCurrency.btc) ||
        trade.provider == ExchangeProviderDescription.xmrto ||
        _isTokenBelongingToWallet(CryptoCurrency.eth) ||
        _isTokenBelongingToWallet(CryptoCurrency.maticpoly) ||
        _isTokenBelongingToWallet(CryptoCurrency.baseEth) ||
        _isTokenBelongingToWallet(CryptoCurrency.arbEth) ||
        _isTokenBelongingToWallet(CryptoCurrency.trx) ||
        _isTokenBelongingToWallet(CryptoCurrency.sol) ||
        _isTokenBelongingToWallet(CryptoCurrency.bnb);

    if (!canSend) {
      return 'Wallet currency ${wallet.currency.title} does not match trade from currency ${tradeFrom.title} or is not a supported token for this wallet.';
    }

    return null;
  }

  void _logCanSendError(Trade? trade, WalletBase wallet, String error) {
    ExchangeProviderLogger.logError(
      provider: trade?.provider,
      function: '_checkIfCanSend',
      error: error,
      requestData: {
        'tradeId': trade?.id,
        'tradeFrom': trade?.from?.title,
        'tradeFromTag': trade?.from?.tag,
        'tradeTo': trade?.to?.title,
        'tradeToTag': trade?.to?.tag,
        'walletName': wallet.name,
        'walletCurrency': wallet.currency.title,
        'walletCurrencyTag': wallet.currency.tag,
      },
    );
  }

  static bool _checkIfSwapsXYZCanSendFromExternal(Trade trade, WalletBase wallet) {
    final provider = trade.provider;

    if (provider == ExchangeProviderDescription.swapsXyz && isEVMCompatibleChain(wallet.type)) {
      if (trade.routerData != null && trade.routerData != '0x') {
        return false;
      }
    }
    return true;
  }

  PaymentURI? get paymentUri {
    final inputAddress = trade.inputAddress;
    final amount = trade.amount;
    final fromCurrency = trade.from;

    if (inputAddress == null || inputAddress.isEmpty || fromCurrency == null) {
      return null;
    }

    // Using the trade's `from` currency so the external-send QR encodes the correct scheme.
    final uriWalletType = cryptoCurrencyOrTokenToWalletType(fromCurrency);

    // for other currencies that we don't have wallets for
    if (uriWalletType == null) {
      return ExternalAddressURI(address: inputAddress, amount: amount);
    }

    printV(uriWalletType);

    switch (uriWalletType) {
      case WalletType.bitcoin:
        return BitcoinURI(address: inputAddress, amount: amount);
      case WalletType.bitcoinCash:
        return BitcoinCashURI(address: inputAddress, amount: amount);
      case WalletType.dogecoin:
        return DogeURI(address: inputAddress, amount: amount);
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        return _createERC681URI(fromCurrency, inputAddress, amount);
      case WalletType.solana:
        return SolanaURI(
          amount: amount,
          address: inputAddress,
          contractAddress: TokenUtilities.findSolanaTokenMint(fromCurrency),
        );
      case WalletType.tron:
        return TronURI(
          amount: amount,
          address: inputAddress,
          contractAddress: TokenUtilities.findTronTokenContract(fromCurrency),
        );
      case WalletType.monero:
        return MoneroURI(address: inputAddress, amount: amount);
      case WalletType.wownero:
        return MoneroURI(address: inputAddress, amount: amount);
      case WalletType.litecoin:
        return LitecoinURI(amount: amount, address: inputAddress);
      case WalletType.nano:
        return NanoURI(amount: amount, address: inputAddress);
      case WalletType.zano:
        return ZanoURI(amount: amount, address: inputAddress);
      case WalletType.decred:
        return DecredURI(amount: amount, address: inputAddress);
      case WalletType.zcash:
        return ZcashURI(amount: amount, address: inputAddress);
      case WalletType.banano:
      case WalletType.none:
      case WalletType.haven:
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
      final erc20Token = TokenUtilities.findErc20Token(currency, wallet) ??
          TokenUtilities.findErc20TokenForSwap(currency);

      if (erc20Token != null) {
        return ERC681URI(
          chainId: chainId,
          address: address,
          amount: amount,
          contractAddress: erc20Token.contractAddress,
          tokenDecimals: erc20Token.decimal,
        );
      }
      return null;
    }
  }

  @computed
  String get qrImage => getQrImage(wallet.type);
}
