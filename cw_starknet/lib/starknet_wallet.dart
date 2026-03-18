import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto_lib;
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/starknet_transaction_history.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:cw_starknet/starknet_wallet_addresses.dart';
import 'package:hex/hex.dart';
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
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _client = StarknetWalletClient(),
        walletAddresses = StarknetWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, StarknetBalance>.of(
            {CryptoCurrency.strk: initialBalance ?? StarknetBalance(0.0)}),
        super(walletInfo, derivationInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = StarknetTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );
  }

  static const String openZeppelinAccountClassHashHex =
      '0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381';

  final String _password;
  final String? _mnemonic;
  final String? _hexPrivateKey;
  final EncryptionFileUtils encryptionFileUtils;

  late final StarknetWalletClient _client;
  late String _runtimePrivateKeyHex;
  late String _starknetPublicKeyHex;
  late String _accountAddressHex;

  StarknetWalletClient get client => _client;

  Timer? _transactionsUpdateTimer;
  bool _isTransactionUpdating = false;
  int? _lastSyncedBlock;

  double? estimatedFee;

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
  Object get keys => throw UnimplementedError('keys');

  String get accountAddress => _accountAddressHex;

  String get publicKey => _starknetPublicKeyHex;

  @override
  String? get seed => _mnemonic;

  @override
  String get privateKey => _hexPrivateKey ?? '';

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: _mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
      );

  Future<void> init() async {
    await ensureStarknetRustInitialized();
    final normalizedPrivateKeyHex =
        (_hexPrivateKey?.trim().isEmpty ?? true) ? null : _hexPrivateKey!.trim();

    final response = await rust_api.deriveAccount(
      mnemonic: _mnemonic,
      passphrase: passphrase,
      privateKeyHex: normalizedPrivateKeyHex,
      accountClassHashHex: openZeppelinAccountClassHashHex,
    );
    final accountData = unwrapDerivedAccountDataResponse(response);

    _runtimePrivateKeyHex = accountData.privateKeyHex;
    _starknetPublicKeyHex = accountData.publicKeyHex;
    _accountAddressHex = accountData.accountAddressHex;

    walletInfo.address = _accountAddressHex;

    await walletAddresses.init();
    await transactionHistory.init();

    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

  @override
  Future<void> changePassword(String password) => throw UnimplementedError('changePassword');

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
        throw Exception('Starknet node connection failed');
      }

      _client.setupAccount(
        privateKeyHex: _runtimePrivateKeyHex,
        addressHex: _accountAddressHex,
      );

      _setTransactionUpdateTimer();
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      printV('Failed to connect Starknet wallet to node: $e');
      syncStatus = FailedSyncStatus();
    }
  }

  static BigInt _parseAmountToWei(String amount) {
    final parts = amount.split('.');
    final wholePart = parts[0];
    final fracPart = parts.length > 1 ? parts[1].padRight(18, '0').substring(0, 18) : '0' * 18;
    return BigInt.parse('$wholePart$fracPart');
  }

  static String _messageHashHex(String message) =>
      '0x${HEX.encode(crypto_lib.sha256.convert(utf8.encode(message)).bytes)}';

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final starkCredentials = credentials as StarknetTransactionCredentials;
    final output = starkCredentials.outputs.first;

    final destinationAddress = output.isParsedAddress ? output.extractedAddress! : output.address;

    BigInt amountWei;
    double displayAmount;
    if (output.sendAll) {
      final balanceValue = balance[currency]?.balance ?? 0.0;
      displayAmount = balanceValue;
      amountWei = _parseAmountToWei(balanceValue.toStringAsFixed(18));
    } else {
      final cryptoAmount = output.cryptoAmount ?? '0.0';
      displayAmount = double.tryParse(cryptoAmount) ?? 0.0;
      amountWei = _parseAmountToWei(cryptoAmount);
    }

    final tokenAddressHex = starkCredentials.currency == CryptoCurrency.strk
        ? StarknetTokenAddresses.strk
        : StarknetTokenAddresses.eth;

    return _client.createTransaction(
      recipientAddressHex: destinationAddress,
      amountWei: amountWei.toString(),
      tokenAddressHex: tokenAddressHex,
      destinationAddressHex: destinationAddress,
      inputAmount: displayAmount,
      accountClassHashHex: openZeppelinAccountClassHashHex,
    );
  }

  @override
  Future<Map<String, StarknetTransactionInfo>> fetchTransactions() async {
    try {
      final events = await _client.fetchTransferEvents(
        accountAddressHex: _accountAddressHex,
        fromBlock: _lastSyncedBlock,
      );
      if (events.isEmpty) {
        return {};
      }

      final result = <String, StarknetTransactionInfo>{};
      for (final event in events) {
        final key = event.transactionHash;
        if (result.containsKey(key) && !event.isOutgoing) {
          continue;
        }

        final timestampSeconds =
            event.blockTimestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

        result[key] = StarknetTransactionInfo(
          id: event.transactionHash,
          starknetAmount: event.amountAsDouble,
          direction:
              event.isOutgoing ? TransactionDirection.outgoing : TransactionDirection.incoming,
          blockTime: DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000),
          isPending: false,
          tokenSymbol: event.tokenSymbol,
          to: event.to,
          from: event.from,
          txFee: event.txFeeAsDouble,
        );

        if (event.blockNumber != null) {
          _lastSyncedBlock = (_lastSyncedBlock == null)
              ? event.blockNumber!
              : (event.blockNumber! > _lastSyncedBlock! ? event.blockNumber! : _lastSyncedBlock!);
        }
      }

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
  Future<void> rescan({required int height}) => throw UnimplementedError('rescan');

  @override
  Future<void> save() async {
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      saveKeysFile(_password, encryptionFileUtils, true);
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
      await _getEstimatedFees();
      await updateTransactionsHistory();

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      printV('Failed to sync Starknet wallet balance: $e');
      syncStatus = FailedSyncStatus();
    }
  }

  Future<void> _updateBalance({bool throwOnError = false}) async {
    try {
      final strkBalance = await _client.getStrkBalance(_accountAddressHex);
      balance[CryptoCurrency.strk] = strkBalance;
      await save();
    } catch (e) {
      printV('Preserving previous Starknet balance after refresh failure: $e');
      if (throwOnError) {
        rethrow;
      }
    }
  }

  Future<void> _getEstimatedFees() async {
    try {
      estimatedFee = await _client.getEstimatedTransferFee(_accountAddressHex);
    } catch (e) {
      printV('Error estimating Starknet fees: $e');
      estimatedFee = 0.0;
    }
  }

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'private_key': _hexPrivateKey,
        'balance': balance[currency]?.toJSON(),
        'passphrase': passphrase,
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

    final balance = StarknetBalance.fromJSON(data?['balance'] as String?) ?? StarknetBalance(0.0);

    final WalletKeysData keysData;
    if (!hasKeysFile) {
      final mnemonic = data!['mnemonic'] as String?;
      final privateKey = data['private_key'] as String?;
      final passphrase = data['passphrase'] as String?;

      keysData = WalletKeysData(
        mnemonic: mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
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
      initialBalance: balance,
      encryptionFileUtils: encryptionFileUtils,
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
      _getEstimatedFees();
    });
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    await ensureStarknetRustInitialized();

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
}
