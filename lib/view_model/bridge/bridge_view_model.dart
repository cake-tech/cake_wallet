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
import 'package:cw_core/amount/amount_sanitizer.dart';
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
  final WalletManager walletManager;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;
  final BridgeTransfersStore bridgeTransfersStore;
  final Map<String, Completer<void>> _pollingCancellers = {};

  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(minutes: 5);
  static const _destinationPollInterval = Duration(seconds: 5);
  static const _destinationPollTimeout = Duration(minutes: 10);

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
  BridgeQuote? quote;

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
  String get fiatCurrencyTitle => settingsStore.fiatCurrency.title;

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
    if (selectedToken == null) return "0.00";

    return amountParsingProxy.asDisplayString(
      Money(selectedTokenBalance, selectedToken!),
    );
  }

  @computed
  String get amountDisplayFormatted {
    if (selectedToken == null) return "0.00";

    return amountParsingProxy.getDisplayCryptoAmount(
      amount.replaceAll(',', '.'),
      selectedToken!,
    );
  }

  DecimalAmountValidator get decimalAmountValidator => DecimalAmountValidator(
        currency: selectedToken!,
        isAutovalidate: true,
      );

  @computed
  String get fiatAmountFormatted {
    try {
      if (amount.isEmpty) return '';

      final price = fiatConversionStore.prices[selectedToken!];
      if (price == null) return '';

      final forFiat =
          amountParsingProxy.getDisplayCryptoAmount(amount.replaceAll(',', '.'), selectedToken!);

      return calculateFiatAmount(price: price, cryptoAmount: forFiat);
    } catch (_) {
      return '';
    }
  }

  @computed
  String get quoteNativeFee {
    if (quote == null) return '—';

    return amountParsingProxy.asDisplayString(Money(quote!.nativeFee, wallet.currency));
  }

  @computed
  String get quoteNativeFeeFormattedForDisplay {
    if (quoteNativeFee.isEmpty) return '';

    return '${quoteNativeFee.withMaxDecimals(8)} ${wallet.currency.title}';
  }

  @computed
  String get quoteNativeFiatFeeFormattedForDisplay {
    try {
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

      return '(${fiatCurrencyTitle} $fiatFeeFormatted)';
    } catch (_) {
      return '';
    }
  }

  @computed
  bool get canProceedToDestinationNetwork {
    if (amount.isEmpty) return false;

    if (selectedToken.isNotErc20) return false;

    if (amountError != null) return false;

    final validAmount = amountParsingProxy.tryParseCryptoString(
      amount.sanitized(),
      selectedToken!,
    );
    return validAmount != null && validAmount > Money.zero(selectedToken!);
  }

  @computed
  BigInt get selectedTokenBalance {
    if (selectedToken == null) return BigInt.zero;

    try {
      final bal = wallet.balance[selectedToken!];

      return bal?.available.amount ?? BigInt.zero;
    } catch (e) {
      return BigInt.zero;
    }
  }

  @computed
  String? get amountError {
    if (selectedToken == null) return null;

    final amountBigInt = amountParsingProxy.tryParseCryptoString(
      amount.replaceAll(',', '.'),
      selectedToken!,
    );

    if (amountBigInt == null || amountBigInt == BigInt.zero) return null;
    if (amountBigInt.amount > selectedTokenBalance) {
      return 'Insufficient balance for ${selectedToken!.title} token.';
    }

    return null;
  }

  @action
  void applyInitialBridgeToken(CryptoCurrency asset) {
    final token = availableUSDT0Tokens.firstWhereOrNull((t) => t == asset);
    if (token != null) {
      setSelectedToken(token);
    }
  }

  @action
  void setDestinationChain(int chainId) => destinationChainId = chainId;

  @action
  void setSelectedToken(CryptoCurrency token) => selectedToken = token;

  @action
  void setAmount(String value) => amount = value;

  @action
  void setMaxAmount() {
    final token = selectedToken.asErc20;
    if (token == null) return;

    if (selectedTokenBalance == BigInt.zero) {
      setAmount('');
      return;
    }
    setAmount(
      amountParsingProxy.asDisplayString(Money(selectedTokenBalance, token)),
    );
  }

  @action
  void setRecipientAddress(String value, {String? destWalletName}) {
    recipientAddress = value;
    destinationWalletName = destWalletName;
  }

  Future<void> _ensureFiatPriceFor(CryptoCurrency crypto) async {
    if (fiatConversionStore.prices[crypto] != null) return;

    try {
      final p = await FiatConversionService.fetchPrice(
        crypto: crypto,
        fiat: settingsStore.fiatCurrency,
        torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly,
      );

      runInAction(() {
        fiatConversionStore.prices[crypto] = p;
      });
    } catch (e) {
      printV('Error ensuring fiat price for $crypto: $e');
    }
  }

  @action
  Future<void> ensureFiatPriceForSelectedToken() async {
    await _ensureFiatPriceFor(selectedToken!);
  }

  @action
  Future<void> ensureFiatPriceForNativeCurrency() async {
    await _ensureFiatPriceFor(wallet.currency);
  }

  @action
  Future<void> loadReceivingWalletOptions() async {
    if (!isEVMCompatibleChain(wallet.type)) return;

    if (destinationChainId == null) return;

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
    } catch (e) {
      printV('Error loading receiving wallet options: $e');
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

    final token = selectedToken.asErc20;
    if (token == null) return;

    final check = _parseAndValidateAmount(token);
    if (check.error != null) {
      quoteError = check.error;
      return;
    }

    final src = sourceChainId!;
    final dst = destinationChainId!;
    final amountBigInt = check.parsedAmount!;

    isQuoteLoading = true;
    _clearQuoteState();

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

    final token = selectedToken.asErc20;
    if (token == null) return;

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
      _pollForConfirmation(record, wallet, isSource: true);
    } catch (e) {
      executeError = e.toString();
    } finally {
      isExecuting = false;
    }
  }

  @override
  void onWalletChange(WalletBase wallet) {
    _cancelAllPolling();
    _resumePollingForActiveTransfers(wallet);
  }

  void _resumePollingForActiveTransfers(WalletBase wallet) {
    if (!isEVMCompatibleChain(wallet.type)) return;

    final activeTransfers = bridgeTransfersStore.bridgeTransfers
        .where((t) => t.walletId == wallet.name && t.isActive)
        .toList();

    for (final transfer in activeTransfers) {
      if (transfer.status == 'submitted' || transfer.status == 'confirming') {
        _pollForConfirmation(transfer, wallet, isSource: true);
      } else if (transfer.status == 'initiated') {
        _pollForConfirmation(transfer, wallet, isSource: false);
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

    try {
      await bridgeTransfersStore.updateTransfer(record);
    } catch (e) {
      printV('USDT0 bridge: Error updating transfer status: $e');
    }
  }

  Future<void> _pollForConfirmation(
    BridgeTransfer record,
    WalletBase wallet, {
    required bool isSource,
  }) async {
    final canceller = Completer<void>();
    final recordId = isSource ? record.id : '${record.id}_dest';
    final pollInterval = isSource ? _pollInterval : _destinationPollInterval;
    final pollTimeout = isSource ? _pollTimeout : _destinationPollTimeout;
    final walletId = wallet.name;
    final deadline = DateTime.now().add(pollTimeout);

    _pollingCancellers[recordId] = canceller;

    try {
      while (DateTime.now().isBefore(deadline)) {
        await Future.any([
          Future.delayed(pollInterval),
          canceller.future,
        ]);

        if (canceller.isCompleted || !_isValidWalletContext(walletId)) return;

        if (isSource) {
          final receipt = await _fetchTransactionReceipt(record, wallet);

          if (receipt != null) {
            final isTransactionSuccessful = receipt == true;
            await _updateTransferStatus(
              record,
              isTransactionSuccessful ? 'initiated' : 'failed',
              confirmedAt: isTransactionSuccessful ? DateTime.now() : null,
              errorMessage: !isTransactionSuccessful ? 'Transaction reverted' : null,
            );

            if (isTransactionSuccessful) {
              await Future.delayed(const Duration(seconds: 1));
              if (_isValidWalletContext(walletId)) {
                _pollForConfirmation(record, wallet, isSource: false);
              }
            }

            return;
          }

          continue;
        } else {
          final status = await _fetchLayerZeroMessageStatus(record, wallet);

          if (status != null) {
            final statusMessage = _getStatusMessage(status, record);
            await _updateTransferStatus(
              record,
              statusMessage,
              errorMessage:
                  status.isFailed ? status.status?.message ?? 'Bridge message failed' : null,
              statusMessage: status.status?.message,
            );

            if (status.isDelivered || status.isFailed) return;
          }

          continue;
        }
      }

      if (isSource && _isValidWalletContext(walletId)) {
        await _updateTransferStatus(
          record,
          'failed',
          errorMessage: 'Source confirmation timed out',
        );
      }
    } catch (e) {
      printV('USDT0 bridge: Error polling for confirmation: $e');
    } finally {
      _pollingCancellers.remove(recordId);
    }
  }

  String _getStatusMessage(LayerZeroMessageStatus status, BridgeTransfer record) {
    if (status.isDelivered) {
      return 'completed';
    }

    if (status.isFailed) {
      return 'failed';
    }

    return record.status;
  }

  Future<bool?> _fetchTransactionReceipt(BridgeTransfer record, WalletBase wallet) async {
    try {
      return await evm!.getTransactionReceipt(wallet, record.sourceTxHash);
    } catch (e) {
      printV('USDT0 bridge: Error fetching receipt: $e');
      return null;
    }
  }

  Future<LayerZeroMessageStatus?> _fetchLayerZeroMessageStatus(
      BridgeTransfer record, WalletBase wallet) async {
    try {
      return await LayerZeroScanService.getMessageStatus(record.sourceTxHash);
    } catch (e) {
      printV('USDT0 bridge: Error fetching LayerZero status: $e');
      return null;
    }
  }

  @action
  void _clearQuoteState() {
    quote = null;
    quoteError = null;
    executeError = null;
  }

  @action
  void clearOnBridgeSuccess() {
    amount = '';
    recipientAddress = '';
    destinationWalletName = null;
    destinationChainId = null;
    bridgeSuccess = false;
    lastCreatedBridgeTransfer = null;
    _clearQuoteState();
  }

  void _cancelAllPolling() {
    for (final canceller in _pollingCancellers.values) {
      if (!canceller.isCompleted) {
        canceller.complete();
      }
    }
    _pollingCancellers.clear();
  }

  void dispose() {
    _cancelAllPolling();
  }
}

extension CryptoCurrencyX on CryptoCurrency? {
  Erc20Token? get asErc20 {
    final token = this;
    return token is Erc20Token ? token : null;
  }

  bool get isNotErc20 => this == null || this is! Erc20Token;
}
