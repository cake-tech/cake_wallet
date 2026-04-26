import 'dart:async';

import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/view_model/bridge/bridge_receiving_wallet_option.dart';
import 'package:cake_wallet/entities/bridge_transfer.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/core/layerzero_scan_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/bridge_transfers_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';

part 'bridge_view_model.g.dart';

class BridgeViewModel = BridgeViewModelBase with _$BridgeViewModel;

abstract class BridgeViewModelBase extends WalletChangeListenerViewModel with Store {
  BridgeViewModelBase({
    required AppStore appStore,
    required this.bridgeTransfersStore,
    required this.walletManager,
    required this.fiatConversionStore,
    required this.settingsStore,
  })  : _appStore = appStore,
        super(appStore: appStore);

  final AppStore _appStore;

  AmountParsingProxy get amountParsingProxy => _appStore.amountParsingProxy;

  void Function()? onBridgeSuccess;
  final Map<String, Completer<void>> _pollingCancellers = {};
  final BridgeTransfersStore bridgeTransfersStore;
  final WalletManager walletManager;
  final FiatConversionStore fiatConversionStore;
  final SettingsStore settingsStore;

  @observable
  ObservableList<BridgeReceivingWalletOption> bridgeReceivingWalletOptions =
      ObservableList<BridgeReceivingWalletOption>();

  @observable
  bool isBridgeReceivingWalletListLoading = false;

  @observable
  CryptoCurrency? selectedToken;

  @observable
  int? destinationChainId;

  @observable
  String amount = '';

  @observable
  String recipientAddress = '';

  @observable
  String? destinationWalletName;

  @observable
  USDT0Quote? quote;

  @observable
  bool isQuoteLoading = false;

  @observable
  String? quoteError;

  @observable
  bool isExecuting = false;

  @observable
  String? executeError;

  @observable
  bool bridgeSuccess = false;

  @observable
  BridgeTransfer? lastCreatedBridgeTransfer;

  @computed
  int? get sourceChainId => evm!.getSelectedChainId(wallet);

  @computed
  String get sourceAddress => wallet.walletAddresses.address;

  @computed
  List<ChainInfo> get availableDestinationChains {
    if (!isEVMCompatibleChain(wallet.type)) return [];

    return evm!.getUSDT0DestinationChains(wallet);
  }

  @computed
  List<Erc20Token> get availableUSDT0Tokens {
    if (!isEVMCompatibleChain(wallet.type)) return [];

    final tokens = wallet.balance.keys.whereType<Erc20Token>();
    return tokens.where((token) => evm!.isUSDT0Token(wallet, token)).toList(growable: false);
  }

  @computed
  ChainInfo? get destinationChainInfo {
    if (destinationChainId == null) return null;

    return availableDestinationChains.firstWhereOrNull((c) => c.chainId == destinationChainId);
  }

  @computed
  String get tokenBalanceFormatted {
    final token = selectedToken;
    if (token is! Erc20Token) return '0.00';

    return amountParsingProxy.asDisplayString(
      Money(selectedTokenBalance, token),
    );
  }

  @computed
  String get amountDisplayFormatted {
    if (amount.isEmpty) return '';
    final token = selectedToken;
    if (token is! Erc20Token) return amount.replaceAll(',', '.');

    return amountParsingProxy.getDisplayCryptoAmount(
      amount.replaceAll(',', '.'),
      token,
    );
  }


  DecimalAmountValidator get decimalAmountValidator => DecimalAmountValidator(
        currency: selectedToken!,
        isAutovalidate: true,
      );

  @computed
  String get fiatAmountFormatted {
    if (amount.isEmpty) return '';
    final token = selectedToken;
    if (token is! Erc20Token) return '';

    final price = fiatConversionStore.prices[token];
    if (price == null) return '';

    final forFiat = amountParsingProxy.getDisplayCryptoAmount(
      amount.replaceAll(',', '.'),
      token,
    );

    return calculateFiatAmount(
      price: price,
      cryptoAmount: forFiat,
    );
  }

  @computed
  String get fiatCurrencyTitle => settingsStore.fiatCurrency.title;

  @computed
  String get quoteNativeFee {
    if (quote == null) return '—';

    final cur = wallet.currency;
    return amountParsingProxy.asDisplayString(
      Money(quote!.nativeFee, cur));
  }

  @computed
  String get quoteNativeFeeFormattedForDisplay {
    if (quoteNativeFee.isEmpty) return '';

    return '${quoteNativeFee.withMaxDecimals(8)} ${wallet.currency.title}';
  }

  @computed
  String get quoteNativeFiatFeeFormattedForDisplay {
    if (quote == null || quoteNativeFee.isEmpty) return '';

    final price = fiatConversionStore.prices[wallet.currency];
    if (price == null) return '';

    final fiatFeeFormatted = calculateFiatAmount(
      price: price,
      cryptoAmount: amountParsingProxy.getDisplayCryptoAmount(
        quoteNativeFee.replaceAll(',', '.'),
        wallet.currency,
      ),
    );

    return '(${settingsStore.fiatCurrency.title} $fiatFeeFormatted)';
  }

  @computed
  bool get canProceedToDestinationNetwork {
    if (amount.isEmpty) return false;

    if (selectedToken == null || selectedToken is! Erc20Token) return false;

    if (amountError != null) return false;

    final token = selectedToken as Erc20Token;
    final validAmount = amountParsingProxy.tryParseCryptoString(
      amount.replaceAll(',', '.'),
      token,
    );
    return validAmount != null && validAmount > Money(BigInt.zero, token);
  }

  @action
  void applyInitialBridgeToken(CryptoCurrency asset) {
    for (final t in availableUSDT0Tokens) {
      if (t == asset) {
        setSelectedToken(t);
        break;
      }
    }
  }

  @action
  void setDestinationChain(int chainId) {
    destinationChainId = chainId;
    _clearQuoteState();
  }

  @action
  void setSelectedToken(CryptoCurrency token) {
    selectedToken = token;
    _clearQuoteState();
  }

  @action
  void setAmount(String value) {
    amount = value;
    _clearQuoteState();
  }

  @action
  void setMaxAmount() {
    final token = selectedToken;
    if (token is! Erc20Token) return;
    if (selectedTokenBalance == BigInt.zero) {
      setAmount('');
      return;
    }
    setAmount(
      amountParsingProxy.asDisplayString(Money(
        selectedTokenBalance,
        token)
      ),
    );
  }

  @action
  void setRecipientAddress(String value, {String? destWalletName}) {
    recipientAddress = value;
    destinationWalletName = destWalletName;
    _clearQuoteState();
  }

  void _clearQuoteState() {
    quote = null;
    quoteError = null;
    executeError = null;
  }

  Future<void> _ensureFiatPriceFor(CryptoCurrency crypto) async {
    if (fiatConversionStore.prices[crypto] != null) return;

    final p = await FiatConversionService.fetchPrice(
      crypto: crypto,
      fiat: settingsStore.fiatCurrency,
      torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly,
    );

    runInAction(() {
      fiatConversionStore.prices[crypto] = p;
    });
  }

  @action
  Future<void> ensureFiatPriceForSelectedToken() async {
    await _ensureFiatPriceFor(selectedToken!);
  }

  @action
  Future<void> ensureFiatPriceForNativeCurrency() async {
    await _ensureFiatPriceFor(wallet.currency);
  }

  @computed
  BigInt get selectedTokenBalance {
    final bal = wallet.balance[selectedToken];

    return bal?.available.amount ?? BigInt.zero;
  }

  @computed
  String? get amountError {
    if (selectedToken == null || amount.isEmpty) return null;
    if (selectedToken is! Erc20Token) return null;

    final token = selectedToken as Erc20Token;
    final parsedAmount = amountParsingProxy.tryParseCryptoString(
      amount.replaceAll(',', '.'),
      token,
    );
    if (parsedAmount == null || parsedAmount == Money(BigInt.zero, token)) return null;
    if (parsedAmount.amount > selectedTokenBalance) {
      return 'Insufficient balance for ${token.title} token.';
    }

    return null;
  }

  @action
  Future<void> loadReceivingWalletOptions() async {
    if (!isEVMCompatibleChain(wallet.type)) return;

    final destWalletType = evm!.getWalletTypeByChainId(destinationChainId!);

    isBridgeReceivingWalletListLoading = true;
    try {
      await walletManager.updateWalletGroups();
      final all = await WalletInfo.getAll();

      if (destWalletType == null) {
        bridgeReceivingWalletOptions.clear();
        return;
      }

      final filtered =
          all.where((w) => w.type == destWalletType && w.hardwareWalletType == null).toList();

      final options = <BridgeReceivingWalletOption>[];

      for (final wi in filtered) {
        final isCurrent = wi.name == wallet.name;
        options.add(
          BridgeReceivingWalletOption(
            walletInfo: wi,
            isCurrent: isCurrent,
            groupLabel: walletManager.getGroupName(wi),
          ),
        );
      }

      bridgeReceivingWalletOptions
        ..clear()
        ..addAll(options);
    } finally {
      isBridgeReceivingWalletListLoading = false;
    }
  }

  String? missingBridgeFieldsMessage() {
    final src = sourceChainId;
    final dst = destinationChainId;
    final token = selectedToken;

    if (src == null ||
        dst == null ||
        token == null ||
        amount.isEmpty ||
        recipientAddress.trim().isEmpty) {
      return 'Fill all fields';
    }
    return null;
  }

  ({String? error, BigInt? parsedAmount}) _parseAndValidateAmount(Erc20Token token) {
    final parsedAmount = amountParsingProxy.tryParseCryptoString(
      amount.replaceAll(',', '.'),
      token,
    );

    if (parsedAmount == null || parsedAmount == Money(BigInt.zero, token)) {
      return (error: 'Invalid amount', parsedAmount: null);
    }

    if (parsedAmount.amount > selectedTokenBalance) {
      return (
        error: 'Insufficient balance for ${token.title} token.',
        parsedAmount: null,
      );
    }

    return (error: null, parsedAmount: parsedAmount.amount);
  }

  @action
  Future<void> loadQuote() async {
    final missing = missingBridgeFieldsMessage();
    if (missing != null) {
      quoteError = missing;
      return;
    }

    final token = selectedToken!;
    if (token is! Erc20Token) return;

    final check = _parseAndValidateAmount(token);
    if (check.error != null) {
      quoteError = check.error;
      return;
    }

    final src = sourceChainId!;
    final dst = destinationChainId!;
    final amountBigInt = check.parsedAmount!;

    isQuoteLoading = true;
    quoteError = null;
    quote = null;
    executeError = null;

    try {
      quote = await evm!.quoteUSDT0Transfer(
        wallet: wallet,
        sourceChainId: src,
        destinationChainId: dst,
        amount: amountBigInt,
        recipientAddress: recipientAddress.trim(),
      );
    } catch (e) {
      quoteError = e.toString();
    } finally {
      isQuoteLoading = false;
    }
  }

  @action
  Future<void> executeBridge() async {
    if (quote == null) {
      executeError = 'Get a quote first';
      return;
    }

    final missing = missingBridgeFieldsMessage();
    if (missing != null) {
      executeError = missing;
      return;
    }

    final token = selectedToken!;
    if (token is! Erc20Token) return;

    final check = _parseAndValidateAmount(token);
    if (check.error != null) {
      executeError = check.error;
      return;
    }

    final src = sourceChainId!;
    final dst = destinationChainId!;
    final amountBigInt = check.parsedAmount!;

    isExecuting = true;
    executeError = null;
    try {
      final priority = evm!.getDefaultTransactionPriority();
      final pending = await evm!.executeUSDT0Transfer(
        wallet: wallet,
        token: token,
        sourceChainId: src,
        destinationChainId: dst,
        amount: amountBigInt,
        recipientAddress: recipientAddress.trim(),
        quote: quote!,
        priority: priority,
        useBlinkProtection: canSupportBlinkProtection(src),
      );

      final sourceTxHash = pending.evmTxHashFromRawHex ?? pending.id;
      await pending.commit();

      final record = BridgeTransfer(
        id: '${sourceTxHash}_${DateTime.now().millisecondsSinceEpoch}',
        walletId: wallet.name,
        sourceChainId: src,
        destinationChainId: dst,
        tokenSymbol: token.title,
        tokenContract: token.contractAddress,
        amount: amount,
        recipientAddress: recipientAddress.trim(),
        sourceTxHash: sourceTxHash,
        status: 'submitted',
        createdAt: DateTime.now(),
      );

      await bridgeTransfersStore.addTransfer(record);
      runInAction(() {
        quote = null;
        bridgeSuccess = true;
        lastCreatedBridgeTransfer = record;
      });
      onBridgeSuccess?.call();
      _pollForSourceConfirmation(record, wallet);
    } catch (e) {
      executeError = e.toString();
    } finally {
      isExecuting = false;
    }
  }

  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(minutes: 3);
  static const _destinationPollInterval = Duration(seconds: 5);
  static const _destinationPollTimeout = Duration(minutes: 10);

  @override
  void onWalletChange(WalletBase wallet) {
    _cancelAllPolling();
    _resumePollingForActiveTransfers(wallet);
  }

  void _cancelAllPolling() {
    for (final canceller in _pollingCancellers.values) {
      if (!canceller.isCompleted) {
        canceller.complete();
      }
    }
    _pollingCancellers.clear();
  }

  void _resumePollingForActiveTransfers(WalletBase wallet) {
    if (!isEVMCompatibleChain(wallet.type)) return;

    final activeTransfers = bridgeTransfersStore.bridgeTransfers
        .where((t) => t.walletId == wallet.name && t.isActive)
        .toList();

    for (final transfer in activeTransfers) {
      if (transfer.status == 'submitted' || transfer.status == 'confirming') {
        _pollForSourceConfirmation(transfer, wallet);
      } else if (transfer.status == 'initiated') {
        _pollForDestinationCompletion(transfer, wallet);
      }
    }
  }

  bool _isValidWalletContext(String expectedWalletId) {
    return wallet.name == expectedWalletId &&
        isEVMCompatibleChain(wallet.type) &&
        !_pollingCancellers.values.any((c) => c.isCompleted);
  }

  Future<void> _updateTransferStatus(
    BridgeTransfer record,
    String status, {
    String? errorMessage,
    String? statusMessage,
    DateTime? confirmedAt,
  }) async {
    if (!_isValidWalletContext(record.walletId)) return;

    runInAction(() {
      record.updatedAt = DateTime.now();
      record.status = status;
      if (errorMessage != null) record.errorMessage = errorMessage;
      if (statusMessage != null) record.statusMessage = statusMessage;
      if (confirmedAt != null) record.confirmedAt = confirmedAt;
    });
    await bridgeTransfersStore.updateTransfer(record);
  }

  Future<void> _pollForSourceConfirmation(
    BridgeTransfer record,
    WalletBase wallet,
  ) async {
    final canceller = Completer<void>();
    _pollingCancellers[record.id] = canceller;
    final walletId = wallet.name;
    final deadline = DateTime.now().add(_pollTimeout);

    try {
      while (DateTime.now().isBefore(deadline)) {
        await Future.any([
          Future.delayed(_pollInterval),
          canceller.future,
        ]);

        if (canceller.isCompleted || !_isValidWalletContext(walletId)) return;

        bool? receipt;
        try {
          receipt = await evm!.getTransactionReceipt(wallet, record.sourceTxHash);
        } catch (e) {
          printV('USDT0 bridge: Error fetching receipt: $e');
          continue;
        }

        if (receipt == null) continue;

        if (receipt == true) {
          await _updateTransferStatus(
            record,
            'confirming',
            confirmedAt: DateTime.now(),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (canceller.isCompleted || !_isValidWalletContext(walletId)) return;

          await _updateTransferStatus(record, 'initiated');
          _pollForDestinationCompletion(record, wallet);

          return;
        } else if (receipt == false) {
          await _updateTransferStatus(
            record,
            'failed',
            errorMessage: 'Transaction reverted',
          );
          return;
        }
      }

      if (!_isValidWalletContext(walletId)) return;

      await _updateTransferStatus(record, 'initiated');
      _pollForDestinationCompletion(record, wallet);
    } finally {
      _pollingCancellers.remove(record.id);
    }
  }

  Future<void> _pollForDestinationCompletion(
    BridgeTransfer record,
    WalletBase wallet,
  ) async {
    final canceller = Completer<void>();
    _pollingCancellers['${record.id}_dest'] = canceller;
    final walletId = wallet.name;
    final deadline = DateTime.now().add(_destinationPollTimeout);

    try {
      while (DateTime.now().isBefore(deadline)) {
        await Future.any([
          Future.delayed(_destinationPollInterval),
          canceller.future,
        ]);

        if (canceller.isCompleted || !_isValidWalletContext(walletId)) return;

        LayerZeroMessageStatus? status;
        try {
          status = await LayerZeroScanService.getMessageStatus(record.sourceTxHash);
        } catch (e) {
          printV('USDT0 bridge: Error fetching LayerZero status: $e');
          continue;
        }

        if (status == null) continue;

        if (status.isDelivered) {
          await _updateTransferStatus(
            record,
            'completed',
            statusMessage: status.status?.message,
          );
          return;
        }

        if (status.isFailed) {
          await _updateTransferStatus(
            record,
            'failed',
            errorMessage: status.status?.message ?? 'Bridge message failed',
            statusMessage: status.status?.message,
          );
          return;
        }

        await _updateTransferStatus(
          record,
          record.status,
          statusMessage: status.status?.message,
        );
      }
    } finally {
      _pollingCancellers.remove('${record.id}_dest');
    }
  }

  @action
  void clearBridgeSuccess() {
    amount = '';
    recipientAddress = '';
    destinationWalletName = null;
    destinationChainId = null;
    bridgeSuccess = false;
    lastCreatedBridgeTransfer = null;
    _clearQuoteState();
  }

  void dispose() {
    _cancelAllPolling();
  }
}
