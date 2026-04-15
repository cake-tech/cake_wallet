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
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _hardwarePublicKeyHex = hardwarePublicKeyHex,
        _hardwareDerivationPath = hardwareDerivationPath,
        _client = StarknetWalletClient(),
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
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

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
      '0x${HEX.encode(crypto_lib.sha256.convert(utf8.encode(message)).bytes)}';

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final starkCredentials = credentials as StarknetTransactionCredentials;
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

      for (final asset in assets) {
        final tokenAddress = _tokenAddressFor(asset);
        final events = await _client.fetchTransferEvents(
          accountAddressHex: _accountAddressHex,
          tokenAddressHex: tokenAddress,
          tokenSymbol: asset.title,
          fromBlock: _lastSyncedBlock,
        );

        for (final event in events) {
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

          if (event.blockNumber != null) {
            latestBlock = latestBlock == null
                ? event.blockNumber!
                : (event.blockNumber! > latestBlock ? event.blockNumber! : latestBlock);
          }
        }
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

  @override
  Future<void> rescan({required int height}) async {
    final shouldRestartTimer = _transactionsUpdateTimer?.isActive ?? false;
    _transactionsUpdateTimer?.cancel();

    try {
      syncStatus = AttemptingSyncStatus();
      _lastSyncedBlock = height < 0 ? 0 : height;
      estimatedFeesWeiByTokenAddress.clear();

      await transactionHistory.reset();
      await _updateBalance(throwOnError: true);
      await updateTransactionsHistory();
      await _refreshEstimatedFees();

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
      await _refreshEstimatedFees();
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

  Future<void> _refreshEstimatedFees() async {
    final nextQuotes = <String, String>{};
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
        );
        nextQuotes[tokenAddress.toLowerCase()] = quote.overallFeeWei;
      } catch (e) {
        printV('Skipping Starknet fee refresh for ${asset.title}: $e');
      }
    }

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
    final feeWei = estimatedFeesWeiByTokenAddress[_tokenAddressFor(currency).toLowerCase()];
    if (feeWei == null) {
      return null;
    }

    return double.tryParse(formatFixed(BigInt.parse(feeWei), 18, fractionalDigits: 18));
  }

  Future<List<String>> signTypedData(String typedDataJson, {String? address}) async {
    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'Offline Starknet typed-data signing over UR is not implemented yet.',
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

  Future<String> executeCalls(List<StarknetExecutionCall> calls) async {
    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'WalletConnect execution is not available for offline Starknet wallets.',
      );
    }

    final pending = walletInfo.isHardwareWallet
        ? await _client.createHardwareTransaction(
            calls: calls,
            amountWei: '0',
            amountDecimals: 18,
            amountSymbol: CryptoCurrency.strk.title,
            destinationAddress: _accountAddressHex,
            accountClassHashHex: _accountClassHashHex,
            feeWei: '0',
          )
        : await _client.createTransaction(
            calls: calls,
            amountWei: '0',
            amountDecimals: 18,
            amountSymbol: CryptoCurrency.strk.title,
            destinationAddress: _accountAddressHex,
            accountClassHashHex: _accountClassHashHex,
            feeWei: '0',
          );
    await pending.commit();
    return pending.id;
  }

  Future<bool> submitSignedTransactionUR(String urPayload) async {
    final txHash = await _client.submitSignedTransactionUr(urPayload);
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _updateBalance();
      await updateTransactionsHistory();
    }());
    return txHash.isNotEmpty;
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
      _refreshEstimatedFees();
    });
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    await ensureStarknetRustInitialized();

    if (supportsOfflineUrSigning) {
      throw UnsupportedError(
        'Offline Starknet message signing over UR is not implemented yet.',
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

  Future<_FeeQuoteModel> _quoteTransferBatch({
    required String tokenAddress,
    required List<(String, BigInt)> transfers,
  }) async {
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
          )
        : await _client.estimateExecuteFee(
            accountAddressHex: _accountAddressHex,
            accountClassHashHex: _accountClassHashHex,
            calls: calls,
          );

    estimatedFeesWeiByTokenAddress[tokenAddress.toLowerCase()] = quote.overallFeeWei;

    return _FeeQuoteModel(
      overallFeeWei: quote.overallFeeWei,
      executionFeeWei: quote.executionFeeWei,
      deployAccountFeeWei: quote.deployAccountFeeWei,
      accountDeploymentRequired: quote.accountDeploymentRequired,
    );
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
