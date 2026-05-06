import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto_lib;
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/starknet_token.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_starknet/default_starknet_tokens.dart';
import 'package:cw_starknet/hardware/starknet_ledger_service.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_exceptions.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/starknet_transaction_history.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:cw_starknet/starknet_transaction_priority.dart';
import 'package:cw_starknet/starknet_ur.dart';
import 'package:cw_starknet/starknet_wallet_addresses.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'starknet_wallet.g.dart';

class StarknetWallet = StarknetWalletBase with _$StarknetWallet;

abstract class StarknetWalletBase
    extends WalletBase<StarknetBalance, StarknetTransactionHistory, StarknetTransactionInfo>
    with Store, WalletKeysFile {
  StarknetWalletBase({
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    String? mnemonic,
    String? privateKey,
    required String password,
    StarknetBalance? initialBalance,
    required this.encryptionFileUtils,
    this.passphrase,
    String? accountClassHashHex,
    String? hardwarePublicKeyHex,
    String? hardwareDerivationPath,
    int? initialLastSyncedBlock,
    StarknetWalletClient? client,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _hardwarePublicKeyHex = hardwarePublicKeyHex,
        _hardwareDerivationPath = hardwareDerivationPath,
        walletAddresses = StarknetWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, StarknetBalance>.of(
          {CryptoCurrency.strk: initialBalance ?? StarknetBalance.zero()},
        ),
        super(walletInfo, derivationInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = StarknetTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );

    if (!CakeHive.isAdapterRegistered(StarknetToken.typeId)) {
      CakeHive.registerAdapter(StarknetTokenAdapter());
    }

    _accountClassHashHex = _normalizeAccountClassHashHex(accountClassHashHex);
    _lastSyncedBlock = initialLastSyncedBlock;
    _client = client ?? StarknetWalletClient();
  }

  static const String openZeppelinAccountClassHashHex =
      '0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381';

  String _password;
  final String? _mnemonic;
  final String? _hexPrivateKey;
  final EncryptionFileUtils encryptionFileUtils;

  late final StarknetWalletClient _client;
  late final Box<StarknetToken> starknetTokensBox;
  late String _runtimePrivateKeyHex;
  late String _starknetPublicKeyHex;
  late String _accountAddressHex;
  late String _accountClassHashHex;
  String? _hardwarePublicKeyHex;
  final String? _hardwareDerivationPath;
  HardwareWalletService? _hardwareWalletService;
  StarknetTransactionPriority _currentFeePriority = StarknetTransactionPriority.medium;
  int? _estimatedFeePriorityRaw;
  final Map<String, _FeeQuoteModel> _estimatedFeeQuotesByTokenAddress = {};

  StarknetWalletClient get client => _client;

  Timer? _transactionsUpdateTimer;
  bool _isTransactionUpdating = false;
  int? _lastSyncedBlock;

  @observable
  ObservableMap<String, String> estimatedFeesWeiByTokenAddress = ObservableMap<String, String>();

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, StarknetBalance> balance =
      ObservableMap<CryptoCurrency, StarknetBalance>();

  @override
  Object get keys => <String, String>{
        'address': accountAddress,
        'publicKey': publicKey,
        if (privateKey.isNotEmpty) 'privateKey': privateKey,
        if (_hardwareDerivationPath?.isNotEmpty ?? false)
          'derivationPath': _hardwareDerivationPath!,
        'accountClassHash': accountClassHashHex,
      };

  @override
  bool get hasRescan => true;

  String get accountAddress => _accountAddressHex;

  String get publicKey => _starknetPublicKeyHex;

  String get accountClassHashHex => _accountClassHashHex;

  bool get supportsOfflineUrSigning =>
      walletInfo.isHardwareWallet &&
      _starknetPublicKeyHex.isNotEmpty &&
      _hardwareWalletService == null;

  List<StarknetToken> get starknetTokenCurrencies => starknetTokensBox.values.toList();

  @override
  String? get seed => _mnemonic;

  @override
  String get privateKey => _hexPrivateKey ?? '';

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: _mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
        publicKey: _hardwarePublicKeyHex,
        derivationPath: _hardwareDerivationPath,
        accountClassHashHex: _accountClassHashHex,
      );

  Future<void> init() async {
    await ensureStarknetRustInitialized();
    await _initStarknetTokensBox();

    if (walletInfo.isHardwareWallet) {
      _runtimePrivateKeyHex = '';
      _starknetPublicKeyHex = await _resolveHardwarePublicKeyHex();
      _accountAddressHex = await _resolveHardwareAccountAddress(_starknetPublicKeyHex);
    } else {
      final normalizedPrivateKeyHex =
          (_hexPrivateKey?.trim().isEmpty ?? true) ? null : _hexPrivateKey!.trim();

      final response = await rust_api.deriveAccount(
        mnemonic: _mnemonic,
        passphrase: passphrase,
        privateKeyHex: normalizedPrivateKeyHex,
        accountClassHashHex: _accountClassHashHex,
      );
      final accountData = unwrapDerivedAccountDataResponse(response);

      _runtimePrivateKeyHex = accountData.privateKeyHex;
      _starknetPublicKeyHex = accountData.publicKeyHex;
      _accountAddressHex = accountData.accountAddressHex;
    }

    walletInfo.address = _accountAddressHex;

    await walletAddresses.init();
    await transactionHistory.init();

    _ensureBalanceEntries();
    await save();
  }

  void setHardwareWalletService(HardwareWalletService service) {
    _hardwareWalletService = service;
    _client.setHardwareWalletService(service);
  }

  Future<void> _initStarknetTokensBox() async {
    final boxName = '${walletInfo.name.replaceAll(" ", "_")}_${StarknetToken.boxName}';
    starknetTokensBox = await CakeHive.openBox<StarknetToken>(boxName);
    _addInitialTokens();
  }

  void _addInitialTokens() {
    final initialTokens = DefaultStarknetTokens().initialStarknetTokens;
    for (final token in initialTokens) {
      if (!starknetTokensBox.containsKey(token.contractAddress)) {
        starknetTokensBox.put(token.contractAddress, token);
      } else {
        final existingToken = starknetTokensBox.get(token.contractAddress)!;
        starknetTokensBox.put(
          token.contractAddress,
          StarknetToken.copyWith(token, enabled: existingToken.enabled),
        );
      }
    }
  }

  void _ensureBalanceEntries() {
    balance[CryptoCurrency.strk] ??= StarknetBalance.zero(decimals: CryptoCurrency.strk.decimals);
    for (final token in starknetTokenCurrencies.where((token) => token.enabled)) {
      balance[token] ??= StarknetBalance.zero(decimals: token.decimal);
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    final normalizedPriority = _normalizeTransactionPriority(priority);
    if (_estimatedFeePriorityRaw != normalizedPriority.raw) {
      return 0;
    }

    final asset = balance.keys.contains(currency) ? currency : CryptoCurrency.strk;
    final feeQuote = _estimatedFeeQuotesByTokenAddress[_tokenAddressFor(asset).toLowerCase()] ??
        _estimatedFeeQuotesByTokenAddress[StarknetTokenAddresses.strk.toLowerCase()];
    if (feeQuote == null) {
      return 0;
    }

    final parsed = BigInt.tryParse(feeQuote.overallFeeWei) ?? BigInt.zero;
    if (parsed > BigInt.from(0x7fffffffffffffff)) {
      return 0x7fffffffffffffff;
    }

    return parsed.toInt();
  }

  @override
  Future<void> updateEstimatedFeesParams(TransactionPriority? priority) async {
    _currentFeePriority = _normalizeTransactionPriority(priority);
    await _refreshEstimatedFees(priority: _currentFeePriority);
  }

  @override
  Future<void> changePassword(String password) async {
    _password = password;
    await transactionHistory.changePassword(password);
    await saveKeysFile(password, encryptionFileUtils);
    await saveKeysFile(password, encryptionFileUtils, true);
    await save();
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    _client.stop();
    _transactionsUpdateTimer?.cancel();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final isConnected = _client.connect(node);
      if (!isConnected) {
        throw StarknetNodeConnectionException();
      }

      if (walletInfo.isHardwareWallet) {
        if (_hardwareWalletService != null &&
            (_hardwareDerivationPath?.trim().isNotEmpty ?? false)) {
          _client.setupHardwareAccount(
            addressHex: _accountAddressHex,
            publicKeyHex: _starknetPublicKeyHex,
            derivationPath: _requireHardwareDerivationPath(),
            service: _hardwareWalletService,
          );
        } else {
          _client.setupExternalSignerAccount(
            addressHex: _accountAddressHex,
            publicKeyHex: _starknetPublicKeyHex,
          );
        }
      } else {
        _client.setupAccount(
          privateKeyHex: _runtimePrivateKeyHex,
          addressHex: _accountAddressHex,
        );
      }

      _setTransactionUpdateTimer();
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      printV('Failed to connect Starknet wallet to node: $e');
      syncStatus = FailedSyncStatus();
    }
  }

  static String _messageHashHex(String message) =>
      _starknetFeltHex(crypto_lib.sha256.convert(utf8.encode(message)).bytes);

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final starkCredentials = credentials as StarknetTransactionCredentials;
    final feePriority = _normalizeTransactionPriority(starkCredentials.priority);
    _currentFeePriority = feePriority;
    final outputs = starkCredentials.outputs;
    if (outputs.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage('Missing Starknet outputs');
    }

    final sendAllOutputs = outputs.where((output) => output.sendAll).toList();
    if (sendAllOutputs.length > 1 || (sendAllOutputs.isNotEmpty && outputs.length > 1)) {
      throw StarknetTransactionCreationException.fromMessage(
        'Send all is only supported for a single Starknet output',
      );
    }

    final asset = _resolveAsset(starkCredentials.currency);
    final tokenAddress = _tokenAddressFor(asset);
    final tokenBalance = balance[asset]?.fullAvailableBalance ?? BigInt.zero;

    if (tokenBalance <= BigInt.zero) {
      throw StarknetTransactionWrongBalanceException(asset);
    }

    final resolvedOutputs = outputs
        .map(
          (output) => (
            output: output,
            address: output.isParsedAddress ? output.extractedAddress! : output.address,
          ),
        )
        .toList();

    for (final resolvedOutput in resolvedOutputs) {
      if (!StarknetWalletClient.isValidAddress(resolvedOutput.address)) {
        throw StarknetInvalidAddressException(resolvedOutput.address);
      }
    }

    final feeTokenBalance = balance[CryptoCurrency.strk]?.fullAvailableBalance ?? BigInt.zero;
    final isNativeFeeToken = asset.titleAndTagEqual(CryptoCurrency.strk);

    BigInt totalAmountWei = BigInt.zero;
    final transfers = <(String address, BigInt amountWei)>[];

    if (sendAllOutputs.isNotEmpty) {
      final destinationAddress = resolvedOutputs.first.address;
      final quote = await _quoteTransferBatch(
        tokenAddress: tokenAddress,
        transfers: [(destinationAddress, tokenBalance)],
        priority: feePriority,
      );

      BigInt sendAmountWei = tokenBalance;
      if (isNativeFeeToken) {
        sendAmountWei -= BigInt.parse(quote.overallFeeWei);
      } else if (feeTokenBalance < BigInt.parse(quote.overallFeeWei)) {
        throw StarknetTransactionCreationException.fromMessage(
          'Insufficient STRK balance to pay Starknet network fees',
        );
      }

      if (sendAmountWei <= BigInt.zero) {
        throw StarknetTransactionWrongBalanceException(asset);
      }

      totalAmountWei = sendAmountWei;
      transfers.add((destinationAddress, sendAmountWei));
    } else {
      for (final resolvedOutput in resolvedOutputs) {
        final cryptoAmount = resolvedOutput.output.cryptoAmount ?? '0';
        final parsedAmount = asset.tryParseAmount(cryptoAmount) ?? BigInt.zero;
        if (parsedAmount <= BigInt.zero) {
          throw StarknetTransactionCreationException.fromMessage(
            'Invalid Starknet amount for ${resolvedOutput.address}',
          );
        }
        totalAmountWei += parsedAmount;
        transfers.add((resolvedOutput.address, parsedAmount));
      }

      final quote = await _quoteTransferBatch(
        tokenAddress: tokenAddress,
        transfers: transfers,
        priority: feePriority,
      );

      if (totalAmountWei > tokenBalance) {
        throw StarknetTransactionWrongBalanceException(asset);
      }

      if (isNativeFeeToken && totalAmountWei + BigInt.parse(quote.overallFeeWei) > tokenBalance) {
        throw StarknetTransactionWrongBalanceException(asset);
      }

      if (!isNativeFeeToken && feeTokenBalance < BigInt.parse(quote.overallFeeWei)) {
        throw StarknetTransactionCreationException.fromMessage(
          'Insufficient STRK balance to pay Starknet network fees',
        );
      }
    }

    final feeQuote = await _quoteTransferBatch(
      tokenAddress: tokenAddress,
      transfers: transfers,
      priority: feePriority,
    );
    final calls = transfers
        .map(
          (transfer) => _buildTransferCall(
            tokenAddress: tokenAddress,
            destinationAddress: transfer.$1,
            amountWei: transfer.$2,
          ),
        )
        .toList();

    final transferSummary = _buildTransferExecutionSummary(
      asset: asset,
      transfers: transfers,
      feeQuote: feeQuote,
      priority: feePriority,
    );

    return supportsOfflineUrSigning
        ? _client.createOfflineTransaction(
            calls: calls,
            amountWei: totalAmountWei.toString(),
            amountDecimals: asset.decimals,
            amountSymbol: asset.title,
            destinationAddress:
                transfers.length == 1 ? transfers.first.$1 : '${transfers.length} recipients',
            accountClassHashHex: _accountClassHashHex,
            feeWei: feeQuote.overallFeeWei,
            feePriorityRaw: feePriority.raw,
            summaryActionName: transferSummary.actionName,
            summaryTokenAddress: transferSummary.tokenAddress,
            summaryAdditionalInfo: transferSummary.additionalInfo,
            preferSummary: transferSummary.preferSummary,
          )
        : walletInfo.isHardwareWallet
            ? _client.createHardwareTransaction(
                calls: calls,
                amountWei: totalAmountWei.toString(),
                amountDecimals: asset.decimals,
                amountSymbol: asset.title,
                destinationAddress:
                    transfers.length == 1 ? transfers.first.$1 : '${transfers.length} recipients',
                accountClassHashHex: _accountClassHashHex,
                feeWei: feeQuote.overallFeeWei,
                feePriorityRaw: feePriority.raw,
                onCommitted: transferSummary.preferSummary
                    ? (txHash) => _recordExecutionSummary(
                          txHash: txHash,
                          summary: transferSummary,
                          feeWei: feeQuote.overallFeeWei,
                        )
                    : null,
              )
            : _client.createTransaction(
                calls: calls,
                amountWei: totalAmountWei.toString(),
                amountDecimals: asset.decimals,
                amountSymbol: asset.title,
                destinationAddress:
                    transfers.length == 1 ? transfers.first.$1 : '${transfers.length} recipients',
                accountClassHashHex: _accountClassHashHex,
                feeWei: feeQuote.overallFeeWei,
                feePriorityRaw: feePriority.raw,
                onCommitted: transferSummary.preferSummary
                    ? (txHash) => _recordExecutionSummary(
                          txHash: txHash,
                          summary: transferSummary,
                          feeWei: feeQuote.overallFeeWei,
                        )
                    : null,
              );
  }

  @override
  Future<Map<String, StarknetTransactionInfo>> fetchTransactions() async {
    try {
      final assets = <CryptoCurrency>[
        CryptoCurrency.strk,
        ...starknetTokenCurrencies.where((token) => token.enabled),
      ];

      final result = <String, StarknetTransactionInfo>{};
      int? latestBlock = _lastSyncedBlock;
      final summaryTransactions = transactionHistory.transactions.values
          .where(
            (transaction) =>
                transaction.additionalInfo['starknetPreferSummary'] == true &&
                transaction.transactionHash.isNotEmpty,
          )
          .toList(growable: false);
      final summaryTransactionHashes = summaryTransactions
          .map((transaction) => transaction.transactionHash.toLowerCase())
          .toSet();

      for (final asset in assets) {
        final tokenAddress = _tokenAddressFor(asset);
        final events = await _client.fetchTransferEvents(
          accountAddressHex: _accountAddressHex,
          tokenAddressHex: tokenAddress,
          tokenSymbol: asset.title,
          fromBlock: _lastSyncedBlock,
        );

        for (final event in events) {
          if (summaryTransactionHashes.contains(event.transactionHash.toLowerCase())) {
            continue;
          }

          final timestampSeconds =
              event.blockTimestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
          final tokenAsset = _assetForTokenAddress(event.tokenAddressHex) ?? asset;

          result[event.eventId] = StarknetTransactionInfo(
            id: event.eventId,
            transactionHash: event.transactionHash,
            amountWei: event.amountWei,
            direction:
                event.isOutgoing ? TransactionDirection.outgoing : TransactionDirection.incoming,
            blockTime: DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000),
            isPending: false,
            tokenAddress: event.tokenAddressHex,
            tokenDecimals: tokenAsset.decimals,
            tokenSymbol: tokenAsset.title,
            to: event.to,
            from: event.from,
            txFeeWei: event.txFeeWei ?? '',
          );

          latestBlock = _maxBlock(latestBlock, event.blockNumber);
        }
      }

      final detailsByHash = await _fetchTransactionDetailsByHash(
        <String>{
          ...result.values.map((transaction) => transaction.transactionHash),
          ...summaryTransactions.map((transaction) => transaction.transactionHash),
        },
      );

      result.updateAll((_, transaction) {
        final details = detailsByHash[transaction.transactionHash.toLowerCase()];
        final enriched =
            details == null ? transaction : _applyTransactionDetails(transaction, details);
        latestBlock = _maxBlock(latestBlock, enriched.height);
        return enriched;
      });

      for (final summaryTransaction in summaryTransactions) {
        final details = detailsByHash[summaryTransaction.transactionHash.toLowerCase()];
        if (details == null) {
          continue;
        }

        final enriched = _applyTransactionDetails(summaryTransaction, details);
        result[summaryTransaction.id] = enriched;
        latestBlock = _maxBlock(latestBlock, enriched.height);
      }

      _lastSyncedBlock = latestBlock;
      return result;
    } catch (e) {
      printV('Error fetching Starknet transactions: $e');
      return {};
    }
  }

  @override
  Future<void> updateTransactionsHistory({List<String>? specificTokenMints}) async {
    if (_isTransactionUpdating) {
      return;
    }

    _isTransactionUpdating = true;
    try {
      final transactions = await fetchTransactions();
      if (transactions.isNotEmpty) {
        transactionHistory.addMany(transactions);
        await transactionHistory.save();
      }
    } catch (e) {
      printV('Error updating Starknet transaction history: $e');
    } finally {
      _isTransactionUpdating = false;
    }
  }

  Future<Map<String, StarknetTransactionDetails>> _fetchTransactionDetailsByHash(
    Set<String> transactionHashes,
  ) async {
    final results = <String, StarknetTransactionDetails>{};

    for (final transactionHash in transactionHashes) {
      final normalizedHash = transactionHash.trim();
      if (normalizedHash.isEmpty) {
        continue;
      }

      final details = await _client.getTransactionDetails(
        transactionHashHex: normalizedHash,
      );
      if (details != null) {
        results[normalizedHash.toLowerCase()] = details;
      }
    }

    return results;
  }

  StarknetTransactionInfo _applyTransactionDetails(
    StarknetTransactionInfo transaction,
    StarknetTransactionDetails details,
  ) {
    final nextAdditionalInfo = <String, dynamic>{
      ...transaction.additionalInfo,
      'starknetTransactionType': details.transactionType,
      'starknetExecutionStatus': details.executionStatus,
      'starknetFinalityStatus': details.finalityStatus,
      if ((details.revertReason?.isNotEmpty ?? false)) 'starknetRevertReason': details.revertReason,
      if ((details.callCount ?? 0) > 0) 'starknetCallCount': details.callCount,
      if ((details.primaryContractAddressHex?.isNotEmpty ?? false))
        'starknetPrimaryContract': details.primaryContractAddressHex,
      if ((details.primaryEntrypoint?.isNotEmpty ?? false))
        'starknetPrimaryEntrypoint': details.primaryEntrypoint,
      if ((details.senderAddressHex?.isNotEmpty ?? false))
        'starknetSenderAddress': details.senderAddressHex,
      if (details.accountDeploymentRequired) 'starknetAccountDeploymentRequired': true,
      if ((details.l1GasMaxAmount?.isNotEmpty ?? false))
        'starknetL1GasMaxAmount': details.l1GasMaxAmount,
      if ((details.l1GasMaxPriceWei?.isNotEmpty ?? false))
        'starknetL1GasMaxPriceWei': details.l1GasMaxPriceWei,
      if ((details.l2GasMaxAmount?.isNotEmpty ?? false))
        'starknetL2GasMaxAmount': details.l2GasMaxAmount,
      if ((details.l2GasMaxPriceWei?.isNotEmpty ?? false))
        'starknetL2GasMaxPriceWei': details.l2GasMaxPriceWei,
      if ((details.l1DataGasMaxAmount?.isNotEmpty ?? false))
        'starknetL1DataGasMaxAmount': details.l1DataGasMaxAmount,
      if ((details.l1DataGasMaxPriceWei?.isNotEmpty ?? false))
        'starknetL1DataGasMaxPriceWei': details.l1DataGasMaxPriceWei,
      if (details.tip != null) 'starknetTip': details.tip,
    };

    final nextActionName = details.actionName ?? transaction.evmSignatureName;
    if (nextActionName != null && nextActionName.isNotEmpty) {
      nextAdditionalInfo['starknetActionLabel'] = _starknetActionLabelFor(nextActionName);
    }

    final timestampSeconds =
        details.blockTimestamp ?? (transaction.blockTime.millisecondsSinceEpoch ~/ 1000);

    return StarknetTransactionInfo(
      id: transaction.id,
      transactionHash: transaction.transactionHash,
      blockTime: DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000),
      to: transaction.to,
      from: transaction.from ?? details.senderAddressHex,
      direction: transaction.direction,
      amountWei: transaction.amountWei,
      tokenAddress: transaction.tokenAddress,
      tokenDecimals: transaction.tokenDecimals,
      tokenSymbol: transaction.tokenSymbol,
      isPending: details.isPending,
      txFeeWei: details.actualFeeWei ?? transaction.txFeeWei,
      evmSignatureName: nextActionName,
      additionalInfo: nextAdditionalInfo,
      height: details.blockNumber ?? transaction.height,
    );
  }

  int? _maxBlock(int? left, int? right) {
    if (right == null) {
      return left;
    }

    if (left == null) {
      return right;
    }

    return right > left ? right : left;
  }

  @override
  Future<void> rescan({required int height}) async {
    final shouldRestartTimer = _transactionsUpdateTimer?.isActive ?? false;
    _transactionsUpdateTimer?.cancel();

    try {
      syncStatus = AttemptingSyncStatus();
      _lastSyncedBlock = height < 0 ? 0 : height;
      _estimatedFeeQuotesByTokenAddress.clear();
      _estimatedFeePriorityRaw = null;
      estimatedFeesWeiByTokenAddress.clear();

      await transactionHistory.reset();
      await _updateBalance(throwOnError: true);
      await updateTransactionsHistory();
      await _refreshEstimatedFees(priority: _currentFeePriority);

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      printV('Error rescanning Starknet wallet: $e');
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    } finally {
      if (shouldRestartTimer) {
        _setTransactionUpdateTimer();
      }
    }
  }

  @override
  Future<void> save() async {
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      await saveKeysFile(_password, encryptionFileUtils, true);
    }

    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await encryptionFileUtils.write(
      path: path,
      password: _password,
      data: toJSON(),
    );
    await transactionHistory.save();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      await _updateBalance(throwOnError: true);
      await _refreshEstimatedFees(priority: _currentFeePriority);
      await updateTransactionsHistory();

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      printV('Failed to sync Starknet wallet balance: $e');
      syncStatus = FailedSyncStatus();
    }
  }

  Future<void> _updateBalance({bool throwOnError = false}) async {
    try {
      final nextBalance = <CryptoCurrency, StarknetBalance>{};
      nextBalance[CryptoCurrency.strk] = await _client.getTokenBalance(
        accountAddressHex: _accountAddressHex,
        tokenAddressHex: StarknetTokenAddresses.strk,
        decimals: CryptoCurrency.strk.decimals,
      );

      for (final token in starknetTokenCurrencies.where((token) => token.enabled)) {
        nextBalance[token] = await _client.getTokenBalance(
          accountAddressHex: _accountAddressHex,
          tokenAddressHex: token.contractAddress,
          decimals: token.decimal,
        );
      }

      balance
        ..clear()
        ..addAll(nextBalance);
      await save();
    } catch (e) {
      printV('Preserving previous Starknet balance after refresh failure: $e');
      if (throwOnError) {
        rethrow;
      }
    }
  }

  Future<void> _refreshEstimatedFees({
    required StarknetTransactionPriority priority,
  }) async {
    _currentFeePriority = priority;
    _estimatedFeePriorityRaw = priority.raw;
    final nextQuotes = <String, String>{};
    final nextQuoteModels = <String, _FeeQuoteModel>{};
    final assets = <CryptoCurrency>[
      CryptoCurrency.strk,
      ...starknetTokenCurrencies.where((token) => token.enabled),
    ];
    final feeTokenBalance = balance[CryptoCurrency.strk]?.fullAvailableBalance ?? BigInt.zero;

    for (final asset in assets) {
      final assetBalance = balance[asset]?.fullAvailableBalance ?? BigInt.zero;
      if (assetBalance <= BigInt.zero) {
        continue;
      }

      if (!asset.titleAndTagEqual(CryptoCurrency.strk) && feeTokenBalance <= BigInt.zero) {
        continue;
      }

      try {
        final tokenAddress = _tokenAddressFor(asset);
        final quote = await _quoteTransferBatch(
          tokenAddress: tokenAddress,
          transfers: [(_accountAddressHex, BigInt.one)],
          priority: priority,
        );
        nextQuotes[tokenAddress.toLowerCase()] = quote.overallFeeWei;
        nextQuoteModels[tokenAddress.toLowerCase()] = quote;
      } catch (e) {
        printV('Skipping Starknet fee refresh for ${asset.title}: $e');
      }
    }

    _estimatedFeeQuotesByTokenAddress
      ..clear()
      ..addAll(nextQuoteModels);
    estimatedFeesWeiByTokenAddress
      ..clear()
      ..addAll(nextQuotes);
  }

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'private_key': _hexPrivateKey,
        'balance': balance[CryptoCurrency.strk]?.toJSON(),
        'passphrase': passphrase,
        'hardware_public_key_hex': _hardwarePublicKeyHex,
        'hardware_derivation_path': _hardwareDerivationPath,
        'account_class_hash_hex': _accountClassHashHex,
        'last_synced_block': _lastSyncedBlock,
      });

  static Future<StarknetWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);
    final path = await pathForWallet(name: name, type: walletInfo.type);

    Map<String, dynamic>? data;
    try {
      final jsonSource = await encryptionFileUtils.read(path: path, password: password);
      data = json.decode(jsonSource) as Map<String, dynamic>;
    } catch (e) {
      if (!hasKeysFile) {
        rethrow;
      }
    }

    final nativeBalance =
        StarknetBalance.fromJSON(data?['balance'] as String?) ?? StarknetBalance.zero();
    final accountClassHashHex = data?['account_class_hash_hex'] as String?;
    final lastSyncedBlock = data?['last_synced_block'] as int?;
    final hardwarePublicKeyHex = data?['hardware_public_key_hex'] as String?;
    final hardwareDerivationPath = data?['hardware_derivation_path'] as String?;

    final WalletKeysData keysData;
    if (!hasKeysFile) {
      final mnemonic = data!['mnemonic'] as String?;
      final privateKey = data['private_key'] as String?;
      final passphrase = data['passphrase'] as String?;

      keysData = WalletKeysData(
        mnemonic: mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
        publicKey: hardwarePublicKeyHex,
        derivationPath: hardwareDerivationPath,
        accountClassHashHex: accountClassHashHex,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    final derivationInfo = await walletInfo.getDerivationInfo();

    return StarknetWallet(
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      password: password,
      passphrase: keysData.passphrase,
      mnemonic: keysData.mnemonic,
      privateKey: keysData.privateKey,
      initialBalance: nativeBalance,
      encryptionFileUtils: encryptionFileUtils,
      hardwarePublicKeyHex: hardwarePublicKeyHex ?? keysData.publicKey,
      hardwareDerivationPath: hardwareDerivationPath ?? keysData.derivationPath,
      accountClassHashHex: accountClassHashHex ?? keysData.accountClassHashHex,
      initialLastSyncedBlock: lastSyncedBlock,
    );
  }

  @override
  Future<void>? updateBalance() async => _updateBalance();

  @override
  Future<bool> checkNodeHealth() async {
    try {
      final blockNumber = await _client.getBlockNumber();
      return blockNumber != null && blockNumber > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> addStarknetToken(StarknetToken token) async {
    await starknetTokensBox.put(token.contractAddress.toLowerCase(), token);
    if (token.enabled) {
      balance[token] ??= StarknetBalance.zero(decimals: token.decimal);
      await _updateBalance();
    }
    await save();
  }

  Future<void> deleteStarknetToken(StarknetToken token) async {
    await starknetTokensBox.delete(token.contractAddress.toLowerCase());
    balance.removeWhere((currency, _) =>
        currency is StarknetToken &&
        currency.contractAddress.toLowerCase() == token.contractAddress.toLowerCase());
    await save();
  }

  Future<StarknetToken?> getStarknetToken(String contractAddress) async {
    final normalized = contractAddress.toLowerCase();
    final existing = starknetTokensBox.get(normalized);
    if (existing != null) {
      return existing;
    }

    try {
      final metadata = await _client.getTokenMetadata(normalized);
      return StarknetToken(
        name: metadata.name,
        symbol: metadata.symbol,
        contractAddress: metadata.tokenAddressHex.toLowerCase(),
        decimal: metadata.decimals,
        iconPath: _defaultIconPathForSymbol(metadata.symbol),
      );
    } catch (e) {
      printV('Error loading Starknet token metadata for $contractAddress: $e');
      return null;
    }
  }

  double? estimatedFeeFor(CryptoCurrency currency) {
    final feeQuote = _estimatedFeeQuotesByTokenAddress[_tokenAddressFor(currency).toLowerCase()] ??
        _estimatedFeeQuotesByTokenAddress[StarknetTokenAddresses.strk.toLowerCase()];
    if (feeQuote == null) {
      return null;
    }

    return double.tryParse(
      formatFixed(BigInt.parse(feeQuote.overallFeeWei), 18, fractionalDigits: 18),
    );
  }

  Future<Map<String, String>> buildMessageSignUr(String message, {String? address}) async {
    final accountAddressHex = address ?? _accountAddressHex;
    return encodeStarknetMessageSignRequestUrMap(
      StarknetMessageSignRequestUrPayload(
        accountAddressHex: accountAddressHex,
        publicKeyHex: _starknetPublicKeyHex,
        message: message,
        messageHashHex: _messageHashHex(message),
      ),
    );
  }

  Future<String> submitSignedMessageUr(String urPayload) async {
    final responsePayload = decodeStarknetMessageSignResponseUr(urPayload);
    await _verifyOfflineSignature(
      messageHashHex: responsePayload.messageHashHex,
      signature: responsePayload.signature,
    );
    return _formatSignature(responsePayload.signature);
  }

  Future<Map<String, String>> buildTypedDataSignUr(String typedDataJson, {String? address}) async {
    final accountAddressHex = address ?? _accountAddressHex;
    final typedDataHashHex = await _client.getTypedDataHash(
      accountAddressHex: accountAddressHex,
      typedDataJson: typedDataJson,
    );
    return encodeStarknetTypedDataSignRequestUrMap(
      StarknetTypedDataSignRequestUrPayload(
        accountAddressHex: accountAddressHex,
        publicKeyHex: _starknetPublicKeyHex,
        typedDataJson: typedDataJson,
        typedDataHashHex: typedDataHashHex,
      ),
    );
  }

  Future<List<String>> submitSignedTypedDataUr(String urPayload) async {
    final responsePayload = decodeStarknetTypedDataSignResponseUr(urPayload);
    await _verifyOfflineSignature(
      messageHashHex: responsePayload.messageHashHex,
      signature: responsePayload.signature,
    );
    return [responsePayload.signature.rHex, responsePayload.signature.sHex];
  }

  Future<List<String>> signTypedData(String typedDataJson, {String? address}) async {
    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'Offline Starknet typed-data signing must be completed via buildTypedDataSignUr().',
      );
    }

    if (walletInfo.isHardwareWallet) {
      final hashHex = await _client.getTypedDataHash(
        accountAddressHex: address ?? _accountAddressHex,
        typedDataJson: typedDataJson,
      );
      return _signWithHardwareWallet(hashHex);
    }

    return _client.signTypedData(
      accountAddressHex: address ?? _accountAddressHex,
      typedDataJson: typedDataJson,
    );
  }

  Future<Map<String, String>> buildExecuteCallsUr(List<StarknetExecutionCall> calls) async {
    final summary = await _buildExecutionSummary(calls);
    final quote = await _quoteExecutionCalls(
      calls,
      priority: _currentFeePriority,
    );
    return _client.buildUnsignedTransactionUr(
      calls: calls,
      amountWei: summary.amountWei,
      amountDecimals: summary.tokenDecimals,
      amountSymbol: summary.tokenSymbol,
      destinationAddress: summary.destinationAddress,
      accountClassHashHex: _accountClassHashHex,
      feeWei: quote.overallFeeWei,
      feePriorityRaw: _currentFeePriority.raw,
      summaryActionName: summary.actionName,
      summaryTokenAddress: summary.tokenAddress,
      summaryAdditionalInfo: {
        ...summary.additionalInfo,
        ..._feeMetadataForQuote(quote, _currentFeePriority),
      },
      preferSummary: summary.preferSummary,
    );
  }

  Future<String> executeCalls(List<StarknetExecutionCall> calls) async {
    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'Offline Starknet execution must be completed via buildExecuteCallsUr().',
      );
    }

    final summary = await _buildExecutionSummary(calls);
    final quote = await _quoteExecutionCalls(
      calls,
      priority: _currentFeePriority,
    );
    final pending = walletInfo.isHardwareWallet
        ? await _client.createHardwareTransaction(
            calls: calls,
            amountWei: summary.amountWei,
            amountDecimals: summary.tokenDecimals,
            amountSymbol: summary.tokenSymbol,
            destinationAddress: summary.destinationAddress,
            accountClassHashHex: _accountClassHashHex,
            feeWei: quote.overallFeeWei,
            feePriorityRaw: _currentFeePriority.raw,
          )
        : await _client.createTransaction(
            calls: calls,
            amountWei: summary.amountWei,
            amountDecimals: summary.tokenDecimals,
            amountSymbol: summary.tokenSymbol,
            destinationAddress: summary.destinationAddress,
            accountClassHashHex: _accountClassHashHex,
            feeWei: quote.overallFeeWei,
            feePriorityRaw: _currentFeePriority.raw,
          );
    await pending.commit();
    await _recordExecutionSummary(
      txHash: pending.id,
      summary: summary.copyWith(
        additionalInfo: {
          ...summary.additionalInfo,
          ..._feeMetadataForQuote(quote, _currentFeePriority),
        },
      ),
      feeWei: quote.overallFeeWei,
    );
    return pending.id;
  }

  Future<String> submitSignedTransactionUR(
    String urPayload, {
    String? requestUrPayload,
  }) async {
    final txHash = await _client.submitSignedTransactionUr(urPayload);
    if (requestUrPayload != null) {
      final requestPayload = decodeStarknetSignRequestUr(requestUrPayload);
      await _recordExecutionSummary(
        txHash: txHash,
        summary: _executionSummaryFromRequestPayload(requestPayload),
        feeWei: requestPayload.feeWei,
      );
    }
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _updateBalance();
      await updateTransactionsHistory();
    }());
    return txHash;
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionsHistoryFileName');

    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionsHistoryFileName');
    }

    await Directory(currentDirPath).delete(recursive: true);
  }

  void _setTransactionUpdateTimer() {
    if (_transactionsUpdateTimer?.isActive ?? false) {
      _transactionsUpdateTimer!.cancel();
    }

    _transactionsUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateBalance();
      updateTransactionsHistory();
      _refreshEstimatedFees(priority: _currentFeePriority);
    });
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    await ensureStarknetRustInitialized();

    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'Offline Starknet message signing must be completed via buildMessageSignUr().',
      );
    }

    if (walletInfo.isHardwareWallet) {
      final signature = await _signWithHardwareWallet(_messageHashHex(message));
      return signature.join(',');
    }

    final response = await rust_api.signMessageHash(
      privateKeyHex: _runtimePrivateKeyHex,
      messageHashHex: _messageHashHex(message),
    );
    final signature = unwrapSignatureResponse(response);
    return '${signature.rHex},${signature.sHex}';
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    final components = signature.split(',');
    if (components.length != 2) {
      return false;
    }

    try {
      await ensureStarknetRustInitialized();
      final response = await rust_api.verifyMessageHashSignature(
        publicKeyHex: _starknetPublicKeyHex,
        messageHashHex: _messageHashHex(message),
        rHex: components[0].trim(),
        sHex: components[1].trim(),
      );
      return unwrapBoolResponse(response);
    } catch (e) {
      printV('Error verifying Starknet signature: $e');
      return false;
    }
  }

  @override
  String get password => _password;

  @override
  final String? passphrase;

  Future<String> _resolveHardwarePublicKeyHex() async {
    final storedPublicKey = _hardwarePublicKeyHex?.trim();
    if (storedPublicKey != null && storedPublicKey.isNotEmpty) {
      return storedPublicKey;
    }

    final service = _hardwareWalletService;
    final derivationPath = _hardwareDerivationPath?.trim();
    if (service is! StarknetLedgerService || derivationPath == null || derivationPath.isEmpty) {
      throw Exception('Missing Starknet hardware wallet public key metadata');
    }
    final publicKeyHex = await service.getPublicKeyHex(derivationPath: derivationPath);
    _hardwarePublicKeyHex = publicKeyHex;
    return publicKeyHex;
  }

  Future<String> _resolveHardwareAccountAddress(String publicKeyHex) async {
    final storedAddress = walletInfo.address.trim();
    if (storedAddress.isNotEmpty) {
      return storedAddress;
    }

    final response = await rust_api.deriveAccountFromPublicKey(
      publicKeyHex: publicKeyHex,
      accountClassHashHex: _accountClassHashHex,
    );
    final accountData = unwrapDerivedAccountDataResponse(response);
    return accountData.accountAddressHex;
  }

  HardwareWalletService _requireHardwareWalletService() {
    final service = _hardwareWalletService;
    if (service == null) {
      throw Exception('Starknet hardware wallet is not connected');
    }
    return service;
  }

  String _requireHardwareDerivationPath() {
    final derivationPath = _hardwareDerivationPath?.trim();
    if (derivationPath == null || derivationPath.isEmpty) {
      throw Exception('Missing Starknet hardware wallet derivation path');
    }
    return derivationPath;
  }

  Uint8List _messageHashBytes(String messageHashHex) {
    final normalized =
        messageHashHex.startsWith('0x') ? messageHashHex.substring(2) : messageHashHex;
    final bytes = Uint8List.fromList(HEX.decode(normalized.padLeft(64, '0')));
    if (bytes.length == 32) {
      return bytes;
    }

    final result = Uint8List(32);
    result.setRange(32 - bytes.length, 32, bytes);
    return result;
  }

  Future<List<String>> _signWithHardwareWallet(String messageHashHex) async {
    final signature = await _requireHardwareWalletService().signMessage(
      message: _messageHashBytes(messageHashHex),
      derivationPath: _requireHardwareDerivationPath(),
    );
    if (signature.length != 64) {
      throw Exception(
        'Unexpected Starknet hardware signature length: ${signature.length}',
      );
    }

    final rHex = '0x${HEX.encode(signature.sublist(0, 32))}';
    final sHex = '0x${HEX.encode(signature.sublist(32, 64))}';
    return [rHex, sHex];
  }

  Future<void> _verifyOfflineSignature({
    required String messageHashHex,
    required StarknetUrSignature signature,
  }) async {
    await ensureStarknetRustInitialized();
    final response = await rust_api.verifyMessageHashSignature(
      publicKeyHex: _starknetPublicKeyHex,
      messageHashHex: messageHashHex,
      rHex: signature.rHex,
      sHex: signature.sHex,
    );

    if (!unwrapBoolResponse(response)) {
      throw Exception('Invalid Starknet signature received from UR response');
    }
  }

  String _formatSignature(StarknetUrSignature signature) => '${signature.rHex},${signature.sHex}';

  Future<_FeeQuoteModel> _quoteExecutionCalls(
    List<StarknetExecutionCall> calls, {
    required StarknetTransactionPriority priority,
  }) async {
    _currentFeePriority = priority;
    final quote = walletInfo.isHardwareWallet
        ? await _client.estimateHardwareExecuteFee(
            accountAddressHex: _accountAddressHex,
            publicKeyHex: _starknetPublicKeyHex,
            accountClassHashHex: _accountClassHashHex,
            calls: calls,
            feePriorityRaw: priority.raw,
          )
        : await _client.estimateExecuteFee(
            accountAddressHex: _accountAddressHex,
            accountClassHashHex: _accountClassHashHex,
            calls: calls,
            feePriorityRaw: priority.raw,
          );

    _estimatedFeePriorityRaw = priority.raw;
    _estimatedFeeQuotesByTokenAddress[StarknetTokenAddresses.strk.toLowerCase()] = _FeeQuoteModel(
      overallFeeWei: quote.overallFeeWei,
      executionFeeWei: quote.executionFeeWei,
      deployAccountFeeWei: quote.deployAccountFeeWei,
      accountDeploymentRequired: quote.accountDeploymentRequired,
    );
    estimatedFeesWeiByTokenAddress[StarknetTokenAddresses.strk.toLowerCase()] = quote.overallFeeWei;
    return _estimatedFeeQuotesByTokenAddress[StarknetTokenAddresses.strk.toLowerCase()]!;
  }

  Future<_FeeQuoteModel> _quoteTransferBatch({
    required String tokenAddress,
    required List<(String, BigInt)> transfers,
    required StarknetTransactionPriority priority,
  }) async {
    _currentFeePriority = priority;
    final calls = transfers
        .map(
          (transfer) => _buildTransferCall(
            tokenAddress: tokenAddress,
            destinationAddress: transfer.$1,
            amountWei: transfer.$2,
          ),
        )
        .toList();

    final quote = walletInfo.isHardwareWallet
        ? await _client.estimateHardwareExecuteFee(
            accountAddressHex: _accountAddressHex,
            publicKeyHex: _starknetPublicKeyHex,
            accountClassHashHex: _accountClassHashHex,
            calls: calls,
            feePriorityRaw: priority.raw,
          )
        : await _client.estimateExecuteFee(
            accountAddressHex: _accountAddressHex,
            accountClassHashHex: _accountClassHashHex,
            calls: calls,
            feePriorityRaw: priority.raw,
          );

    final feeQuote = _FeeQuoteModel(
      overallFeeWei: quote.overallFeeWei,
      executionFeeWei: quote.executionFeeWei,
      deployAccountFeeWei: quote.deployAccountFeeWei,
      accountDeploymentRequired: quote.accountDeploymentRequired,
    );
    _estimatedFeePriorityRaw = priority.raw;
    _estimatedFeeQuotesByTokenAddress[tokenAddress.toLowerCase()] = feeQuote;
    estimatedFeesWeiByTokenAddress[tokenAddress.toLowerCase()] = quote.overallFeeWei;
    return feeQuote;
  }

  Future<_ExecutionSummaryModel> _buildExecutionSummary(
    List<StarknetExecutionCall> calls,
  ) async {
    if (calls.isEmpty) {
      throw StarknetTransactionCreationException.fromMessage('Missing Starknet execution calls');
    }

    final normalizedEntrypoints =
        calls.map((call) => _normalizeEntrypoint(call.entrypoint)).toList(growable: false);

    if (normalizedEntrypoints.every((entrypoint) => entrypoint == 'transfer')) {
      final asset = await _resolveSummaryAsset(calls.first.contractAddressHex);
      var amountWei = BigInt.zero;
      for (final call in calls) {
        amountWei += _decodeUint256Amount(call.calldataHex, amountOffset: 1);
      }

      return _ExecutionSummaryModel(
        actionName: 'transfer',
        amountWei: amountWei.toString(),
        tokenAddress: asset.tokenAddress,
        tokenDecimals: asset.decimals,
        tokenSymbol: asset.symbol,
        destinationAddress: calls.length == 1
            ? (calls.first.calldataHex.isNotEmpty
                ? calls.first.calldataHex.first
                : _accountAddressHex)
            : '${calls.length} recipients',
        additionalInfo: <String, dynamic>{
          'starknetActionLabel': calls.length == 1 ? 'Transfer' : 'Batch transfer',
          'starknetCallCount': calls.length,
        },
        preferSummary: calls.length > 1,
      );
    }

    if (normalizedEntrypoints.every((entrypoint) => entrypoint == 'approve')) {
      final asset = await _resolveSummaryAsset(calls.first.contractAddressHex);
      var amountWei = BigInt.zero;
      for (final call in calls) {
        amountWei += _decodeUint256Amount(call.calldataHex, amountOffset: 1);
      }

      return _ExecutionSummaryModel(
        actionName: 'approval',
        amountWei: amountWei.toString(),
        tokenAddress: asset.tokenAddress,
        tokenDecimals: asset.decimals,
        tokenSymbol: asset.symbol,
        destinationAddress: calls.length == 1
            ? (calls.first.calldataHex.isNotEmpty
                ? calls.first.calldataHex.first
                : calls.first.contractAddressHex)
            : '${calls.length} approvals',
        additionalInfo: <String, dynamic>{
          'starknetActionLabel': calls.length == 1 ? 'Approval' : 'Batch approval',
          'starknetCallCount': calls.length,
          'starknetSpender':
              calls.first.calldataHex.isNotEmpty ? calls.first.calldataHex.first : '',
        },
        preferSummary: true,
      );
    }

    if (normalizedEntrypoints.any(_looksLikeSwapEntrypoint)) {
      final asset = await _resolveSummaryAsset(StarknetTokenAddresses.strk);
      return _ExecutionSummaryModel(
        actionName: 'swap',
        amountWei: '0',
        tokenAddress: asset.tokenAddress,
        tokenDecimals: asset.decimals,
        tokenSymbol: asset.symbol,
        destinationAddress: calls.first.contractAddressHex,
        additionalInfo: <String, dynamic>{
          'starknetActionLabel': 'Swap',
          'starknetCallCount': calls.length,
          'starknetPrimaryEntrypoint': calls.first.entrypoint,
        },
        preferSummary: true,
      );
    }

    final primaryEntrypoint = normalizedEntrypoints.first;
    final actionName = calls.length > 1
        ? 'multicall'
        : (primaryEntrypoint.isEmpty ? 'contract_call' : primaryEntrypoint);
    final defaultAsset = await _resolveSummaryAsset(StarknetTokenAddresses.strk);

    return _ExecutionSummaryModel(
      actionName: actionName,
      amountWei: '0',
      tokenAddress: defaultAsset.tokenAddress,
      tokenDecimals: defaultAsset.decimals,
      tokenSymbol: defaultAsset.symbol,
      destinationAddress:
          calls.length > 1 ? '${calls.length} calls' : calls.first.contractAddressHex,
      additionalInfo: <String, dynamic>{
        'starknetActionLabel': _starknetActionLabelFor(actionName),
        'starknetCallCount': calls.length,
        'starknetPrimaryEntrypoint': calls.first.entrypoint,
        'starknetPrimaryContract': calls.first.contractAddressHex,
      },
      preferSummary: true,
    );
  }

  _ExecutionSummaryModel _executionSummaryFromRequestPayload(
    StarknetSignRequestUrPayload requestPayload,
  ) {
    final tokenAddress = requestPayload.summaryTokenAddress ?? StarknetTokenAddresses.strk;
    final tokenSymbol = requestPayload.amountSymbol;
    final tokenDecimals = requestPayload.amountDecimals;
    final actionName = requestPayload.summaryActionName ?? 'contract_call';

    return _ExecutionSummaryModel(
      actionName: actionName,
      amountWei: requestPayload.amountWei,
      tokenAddress: tokenAddress,
      tokenDecimals: tokenDecimals,
      tokenSymbol: tokenSymbol,
      destinationAddress: requestPayload.destinationAddress,
      additionalInfo: <String, dynamic>{
        'starknetActionLabel': _starknetActionLabelFor(actionName),
        ...?requestPayload.summaryAdditionalInfo,
      },
      preferSummary: requestPayload.preferSummary,
    );
  }

  Future<void> _recordExecutionSummary({
    required String txHash,
    required _ExecutionSummaryModel summary,
    required String feeWei,
  }) async {
    if (!summary.preferSummary || txHash.isEmpty) {
      return;
    }

    final transaction = StarknetTransactionInfo(
      id: txHash,
      transactionHash: txHash,
      blockTime: DateTime.now(),
      to: summary.destinationAddress,
      from: _accountAddressHex,
      direction: TransactionDirection.outgoing,
      amountWei: summary.amountWei,
      tokenAddress: summary.tokenAddress,
      tokenDecimals: summary.tokenDecimals,
      tokenSymbol: summary.tokenSymbol,
      isPending: false,
      txFeeWei: feeWei,
      evmSignatureName: summary.actionName,
      additionalInfo: <String, dynamic>{
        'starknetPreferSummary': true,
        ...summary.additionalInfo,
      },
    );

    transactionHistory.addOne(transaction);
    await transactionHistory.save();
  }

  Future<_SummaryAssetModel> _resolveSummaryAsset(String tokenAddress) async {
    final normalized = tokenAddress.toLowerCase();
    final asset = _assetForTokenAddress(normalized);
    if (asset != null) {
      return _SummaryAssetModel(
        tokenAddress: normalized,
        decimals: asset.decimals,
        symbol: asset.title,
      );
    }

    try {
      final metadata = await _client.getTokenMetadata(normalized);
      return _SummaryAssetModel(
        tokenAddress: metadata.tokenAddressHex.toLowerCase(),
        decimals: metadata.decimals,
        symbol: metadata.symbol,
      );
    } catch (_) {
      return _SummaryAssetModel(
        tokenAddress: StarknetTokenAddresses.strk,
        decimals: CryptoCurrency.strk.decimals,
        symbol: CryptoCurrency.strk.title,
      );
    }
  }

  BigInt _decodeUint256Amount(List<String> calldata, {int amountOffset = 0}) {
    if (calldata.length <= amountOffset) {
      return BigInt.zero;
    }

    final low = _parseFeltBigInt(calldata[amountOffset]);
    final high = calldata.length > amountOffset + 1
        ? _parseFeltBigInt(calldata[amountOffset + 1])
        : BigInt.zero;
    return low + (high << 128);
  }

  BigInt _parseFeltBigInt(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return BigInt.zero;
    }

    if (normalized.startsWith('0x')) {
      return BigInt.parse(normalized.substring(2), radix: 16);
    }

    return BigInt.parse(normalized);
  }

  String _normalizeEntrypoint(String entrypoint) => entrypoint.trim().toLowerCase();

  bool _looksLikeSwapEntrypoint(String entrypoint) {
    final normalized = _normalizeEntrypoint(entrypoint);
    return normalized.contains('swap') ||
        normalized.contains('exact_input') ||
        normalized.contains('exact_output') ||
        normalized.contains('multihop');
  }

  String _starknetActionLabelFor(String actionName) {
    switch (_normalizeEntrypoint(actionName)) {
      case 'approval':
      case 'approve':
        return 'Approval';
      case 'swap':
        return 'Swap';
      case 'multicall':
        return 'Multicall';
      case 'transfer':
        return 'Transfer';
      case 'contract_call':
        return 'Contract call';
      default:
        final normalized = actionName.replaceAll('_', ' ').trim();
        if (normalized.isEmpty) {
          return 'Contract call';
        }
        return normalized[0].toUpperCase() + normalized.substring(1);
    }
  }

  CryptoCurrency _resolveAsset(CryptoCurrency currency) {
    if (currency.titleAndTagEqual(CryptoCurrency.strk)) {
      return CryptoCurrency.strk;
    }

    if (currency is StarknetToken) {
      return currency;
    }

    return starknetTokenCurrencies.firstWhere(
      (token) => token.titleAndTagEqual(currency) || token.title == currency.title,
      orElse: () => throw StarknetTransactionCreationException.fromMessage(
        'Currency ${currency.title} is not enabled for this Starknet wallet',
      ),
    );
  }

  CryptoCurrency? _assetForTokenAddress(String tokenAddress) {
    final normalized = tokenAddress.toLowerCase();
    if (normalized == StarknetTokenAddresses.strk.toLowerCase()) {
      return CryptoCurrency.strk;
    }

    for (final token in starknetTokenCurrencies) {
      if (token.contractAddress.toLowerCase() == normalized) {
        return token;
      }
    }

    return null;
  }

  String _tokenAddressFor(CryptoCurrency asset) {
    if (asset.titleAndTagEqual(CryptoCurrency.strk)) {
      return StarknetTokenAddresses.strk;
    }

    if (asset is StarknetToken) {
      return asset.contractAddress;
    }

    if (asset.title.toUpperCase() == 'ETH') {
      return StarknetTokenAddresses.eth;
    }

    throw StarknetTransactionCreationException.fromMessage(
      'Unknown Starknet token address for ${asset.title}',
    );
  }

  StarknetExecutionCall _buildTransferCall({
    required String tokenAddress,
    required String destinationAddress,
    required BigInt amountWei,
  }) {
    final (low, high) = _uint256Words(amountWei);
    return StarknetExecutionCall(
      contractAddressHex: tokenAddress,
      entrypoint: 'transfer',
      calldataHex: [destinationAddress, low, high],
    );
  }

  _ExecutionSummaryModel _buildTransferExecutionSummary({
    required CryptoCurrency asset,
    required List<(String, BigInt)> transfers,
    required _FeeQuoteModel feeQuote,
    required StarknetTransactionPriority priority,
  }) {
    final totalAmountWei = transfers.fold<BigInt>(
      BigInt.zero,
      (total, transfer) => total + transfer.$2,
    );

    return _ExecutionSummaryModel(
      actionName: 'transfer',
      amountWei: totalAmountWei.toString(),
      tokenAddress: _tokenAddressFor(asset),
      tokenDecimals: asset.decimals,
      tokenSymbol: asset.title,
      destinationAddress:
          transfers.length == 1 ? transfers.first.$1 : '${transfers.length} recipients',
      additionalInfo: <String, dynamic>{
        'starknetActionLabel': transfers.length == 1 ? 'Transfer' : 'Batch transfer',
        'starknetCallCount': transfers.length,
        ..._feeMetadataForQuote(feeQuote, priority),
      },
      preferSummary: feeQuote.accountDeploymentRequired || transfers.length > 1,
    );
  }

  Map<String, dynamic> _feeMetadataForQuote(
    _FeeQuoteModel feeQuote,
    StarknetTransactionPriority priority,
  ) {
    return <String, dynamic>{
      'starknetFeePriorityRaw': priority.raw,
      'starknetFeePriorityLabel': priority.title,
      'starknetExecutionFeeWei': feeQuote.executionFeeWei,
      if ((feeQuote.deployAccountFeeWei?.isNotEmpty ?? false))
        'starknetDeployAccountFeeWei': feeQuote.deployAccountFeeWei,
      if (feeQuote.accountDeploymentRequired) 'starknetAccountDeploymentRequired': true,
    };
  }

  StarknetTransactionPriority _normalizeTransactionPriority(TransactionPriority? priority) {
    if (priority is StarknetTransactionPriority) {
      return priority;
    }

    if (priority != null) {
      try {
        return StarknetTransactionPriority.deserialize(raw: priority.raw);
      } catch (_) {}
    }

    return StarknetTransactionPriority.medium;
  }

  String? _defaultIconPathForSymbol(String symbol) {
    if (symbol.toUpperCase() == 'ETH') {
      return CryptoCurrency.eth.iconPath;
    }

    return null;
  }

  (String, String) _uint256Words(BigInt amount) {
    final mask = (BigInt.one << 128) - BigInt.one;
    final low = amount & mask;
    final high = amount >> 128;
    return ('0x${low.toRadixString(16)}', '0x${high.toRadixString(16)}');
  }

  static String _normalizeAccountClassHashHex(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return openZeppelinAccountClassHashHex;
    }

    final normalized = trimmed.toLowerCase();
    return normalized.startsWith('0x') ? normalized : '0x$normalized';
  }
}

class _FeeQuoteModel {
  const _FeeQuoteModel({
    required this.overallFeeWei,
    required this.executionFeeWei,
    required this.deployAccountFeeWei,
    required this.accountDeploymentRequired,
  });

  final String overallFeeWei;
  final String executionFeeWei;
  final String? deployAccountFeeWei;
  final bool accountDeploymentRequired;
}

class _ExecutionSummaryModel {
  const _ExecutionSummaryModel({
    required this.actionName,
    required this.amountWei,
    required this.tokenAddress,
    required this.tokenDecimals,
    required this.tokenSymbol,
    required this.destinationAddress,
    required this.additionalInfo,
    required this.preferSummary,
  });

  final String actionName;
  final String amountWei;
  final String tokenAddress;
  final int tokenDecimals;
  final String tokenSymbol;
  final String destinationAddress;
  final Map<String, dynamic> additionalInfo;
  final bool preferSummary;

  _ExecutionSummaryModel copyWith({
    String? actionName,
    String? amountWei,
    String? tokenAddress,
    int? tokenDecimals,
    String? tokenSymbol,
    String? destinationAddress,
    Map<String, dynamic>? additionalInfo,
    bool? preferSummary,
  }) {
    return _ExecutionSummaryModel(
      actionName: actionName ?? this.actionName,
      amountWei: amountWei ?? this.amountWei,
      tokenAddress: tokenAddress ?? this.tokenAddress,
      tokenDecimals: tokenDecimals ?? this.tokenDecimals,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      preferSummary: preferSummary ?? this.preferSummary,
    );
  }
}

class _SummaryAssetModel {
  const _SummaryAssetModel({
    required this.tokenAddress,
    required this.decimals,
    required this.symbol,
  });

  final String tokenAddress;
  final int decimals;
  final String symbol;
}

String _starknetFeltHex(List<int> bytes) {
  final hashedValue = BigInt.parse(HEX.encode(bytes), radix: 16);
  return '0x${(hashedValue % _starknetFieldPrime).toRadixString(16)}';
}

final BigInt _starknetFieldPrime = BigInt.parse(
  '800000000000011000000000000000000000000000000000000000000000001',
  radix: 16,
);
