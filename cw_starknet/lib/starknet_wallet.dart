import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_starknet/starknet_balance.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/starknet_transaction_history.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:cw_starknet/starknet_wallet_addresses.dart';
import 'package:hex/hex.dart';
import 'package:mobx/mobx.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:starknet/starknet.dart' hide SyncStatus;
import 'package:crypto/crypto.dart' as crypto_lib;

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

  final String _password;
  final String? _mnemonic;
  final String? _hexPrivateKey;
  final EncryptionFileUtils encryptionFileUtils;

  late final StarknetWalletClient _client;

  StarknetWalletClient get client => _client;

  Timer? _transactionsUpdateTimer;
  bool _isTransactionUpdating = false;
  int? _lastSyncedBlock;

  /// Pre-estimated fee for a standard STRK transfer, updated periodically.
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
  Object get keys => throw UnimplementedError("keys");

  late StarkPrivateKeySigner _signer;
  late Felt _starknetPublicKey;
  late Felt _accountAddress;

  Felt get accountAddress => _accountAddress;
  StarkPrivateKeySigner get signer => _signer;

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

  /// Derives a Stark private key from a BIP39 mnemonic.
  /// Uses the standard EIP-2645 derivation path for Starknet:
  /// m/2645'/1195502025'/1148870696'/0'/0'/0
  static Felt _deriveStarkPrivateKey(String mnemonic, {String? passphrase}) {
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase ?? '');

    // Use HMAC-SHA256 to derive a key from the seed for Stark curve
    // EIP-2645 path: m/2645'/1195502025'/1148870696'/0'/0'/0
    final hmac = crypto_lib.Hmac(crypto_lib.sha256, seed);
    final derivationData = utf8.encode('Starknet key derivation');
    var derived = hmac.convert(derivationData).bytes;

    // Grind to find a valid Stark key (must be < curve order N)
    for (int i = 0; i < 10000; i++) {
      final candidate = BigInt.parse(HEX.encode(derived), radix: 16) % starkN;
      if (candidate > BigInt.zero) {
        return Felt(candidate);
      }
      final nextHmac = crypto_lib.Hmac(crypto_lib.sha256, derived);
      derived = nextHmac.convert([i]).bytes;
    }

    throw Exception('Failed to derive valid Stark private key');
  }

  /// Computes the Starknet account address using OpenZeppelin Account contract class hash.
  /// This uses the standard CREATE2-style address computation.
  static Felt get openZeppelinAccountClassHash =>
      Felt.fromHex('0x01d1777db36cdd06dd62cfde77b1b6ae06412af95d57a13dc40ac77b8a702381');

  static Felt _computeAccountAddress(Felt publicKey) {
    final salt = publicKey;
    final constructorCalldata = [publicKey];

    return Felt(calculateContractAddress(
      deployerAddress: BigInt.zero,
      salt: salt.value,
      classHash: openZeppelinAccountClassHash.value,
      constructorCalldata: constructorCalldata.map((f) => f.value).toList(),
    ));
  }

  Future<void> init() async {
    // Create the signer using either the mnemonic or the privateKey
    Felt starkPrivateKey;
    if (_mnemonic != null) {
      starkPrivateKey = _deriveStarkPrivateKey(_mnemonic!, passphrase: passphrase);
    } else if (_hexPrivateKey != null) {
      starkPrivateKey = Felt.fromHex(_hexPrivateKey!);
    } else {
      throw Exception('Neither mnemonic nor private key provided');
    }

    _signer = StarkPrivateKeySigner(starkPrivateKey);
    _starknetPublicKey = await _signer.getPublicKey();
    _accountAddress = _computeAccountAddress(_starknetPublicKey);

    walletInfo.address = _accountAddress.toHex();

    await walletAddresses.init();
    await transactionHistory.init();

    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

  @override
  Future<void> changePassword(String password) => throw UnimplementedError("changePassword");

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
        throw Exception("Starknet Node connection failed");
      }

      // Setup account on client
      _client.setupAccount(
        signer: _signer,
        address: _accountAddress,
        chainId: StarknetNetwork.mainnet.chainId,
      );

      _setTransactionUpdateTimer();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  /// Parses a string amount to wei (18 decimals) using string manipulation
  /// to avoid floating-point precision loss.
  static BigInt _parseAmountToWei(String amount) {
    final parts = amount.split('.');
    final wholePart = parts[0];
    final fracPart = parts.length > 1
        ? parts[1].padRight(18, '0').substring(0, 18)
        : '0' * 18;
    return BigInt.parse('$wholePart$fracPart');
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final starkCredentials = credentials as StarknetTransactionCredentials;

    final outputs = starkCredentials.outputs;
    final output = outputs.first;

    final destinationAddress = output.isParsedAddress ? output.extractedAddress! : output.address;

    final recipientAddress = Felt.fromHex(destinationAddress);

    BigInt amountWei;
    double displayAmount;
    if (output.sendAll) {
      final bal = balance[currency]?.balance ?? 0.0;
      displayAmount = bal;
      // Use toStringAsFixed for balance-sourced doubles
      amountWei = _parseAmountToWei(bal.toStringAsFixed(18));
    } else {
      final cryptoAmount = output.cryptoAmount ?? '0.0';
      displayAmount = double.tryParse(cryptoAmount) ?? 0.0;
      // Parse string directly to avoid floating-point precision loss
      amountWei = _parseAmountToWei(cryptoAmount);
    }

    final tokenAddress =
        starkCredentials.currency == CryptoCurrency.strk ? StarknetTokens.strk : StarknetTokens.eth;

    return await _client.createTransaction(
      recipientAddress: recipientAddress,
      amount: amountWei,
      tokenAddress: tokenAddress,
      destinationAddressHex: destinationAddress,
      inputAmount: displayAmount,
      accountClassHash: openZeppelinAccountClassHash,
      contractAddressSalt: _starknetPublicKey,
      constructorCalldata: [_starknetPublicKey],
    );
  }

  @override
  Future<Map<String, StarknetTransactionInfo>> fetchTransactions() async {
    try {
      final events = await _client.fetchTransferEvents(
        accountAddress: _accountAddress,
        fromBlock: _lastSyncedBlock,
      );

      if (events.isEmpty) return {};

      // Collect unique block numbers for timestamp lookup
      final blockNumbers = <int>{};
      for (final event in events) {
        if (event.blockNumber != null) {
          blockNumbers.add(event.blockNumber!);
        }
      }

      // Fetch block timestamps
      final timestamps = <int, int>{};
      for (final bn in blockNumbers) {
        timestamps[bn] = await _client.getBlockTimestamp(bn);
      }

      // Fetch fees for each unique transaction (batch by tx hash)
      final txHashes = events.map((e) => e.transactionHash).toSet();
      final fees = <String, double>{};
      for (final hash in txHashes) {
        fees[hash] = await _client.getTransactionFee(Felt.fromHex(hash));
      }

      // Build transaction info map
      final result = <String, StarknetTransactionInfo>{};
      for (final event in events) {
        final key = event.transactionHash;
        // For self-transfers (same tx hash), prefer outgoing direction
        if (result.containsKey(key) && !event.isOutgoing) continue;

        final timestamp = event.blockNumber != null
            ? timestamps[event.blockNumber] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000)
            : DateTime.now().millisecondsSinceEpoch ~/ 1000;

        result[key] = StarknetTransactionInfo(
          id: event.transactionHash,
          starknetAmount: event.amountAsDouble,
          direction: event.isOutgoing
              ? TransactionDirection.outgoing
              : TransactionDirection.incoming,
          blockTime: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
          isPending: false,
          tokenSymbol: event.tokenSymbol,
          to: event.to,
          from: event.from,
          txFee: fees[event.transactionHash] ?? 0.0,
        );

        // Track the highest block we've seen
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
    if (_isTransactionUpdating) return;

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
  Future<void> rescan({required int height}) => throw UnimplementedError("rescan");

  @override
  Future<void> save() async {
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      saveKeysFile(_password, encryptionFileUtils, true);
    }

    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await encryptionFileUtils.write(path: path, password: _password, data: toJSON());
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
      final strkBalance = await _client.getStrkBalance(_accountAddress);
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
      estimatedFee = await _client.getEstimatedTransferFee(_accountAddress);
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
      if (!hasKeysFile) rethrow;
    }

    final balance = StarknetBalance.fromJSON(data?['balance'] as String?) ?? StarknetBalance(0.0);

    final WalletKeysData keysData;
    if (!hasKeysFile) {
      final mnemonic = data!['mnemonic'] as String?;
      final privateKey = data['private_key'] as String?;
      final passphrase = data['passphrase'] as String?;

      keysData = WalletKeysData(mnemonic: mnemonic, privateKey: privateKey, passphrase: passphrase);
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
  Future<void>? updateBalance() async => await _updateBalance();

  @override
  Future<bool> checkNodeHealth() async {
    try {
      final blockNumber = await _client.getBlockNumber();
      return blockNumber != null && blockNumber > 0;
    } catch (e) {
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
    final messageHash =
        Felt.fromHex('0x${HEX.encode(crypto_lib.sha256.convert(utf8.encode(message)).bytes)}');
    final signature = await _signer.signHash(messageHash);
    return '${signature[0].toHex()},${signature[1].toHex()}';
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    // Starknet signature verification requires the original message hash
    // and the public key to verify against
    return false; // TODO: Implement full verification
  }

  @override
  String get password => _password;

  @override
  final String? passphrase;
}
