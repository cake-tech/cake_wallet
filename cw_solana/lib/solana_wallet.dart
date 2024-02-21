import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_solana/default_spl_tokens.dart';
import 'package:cw_solana/file.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_client.dart';
import 'package:cw_solana/solana_exceptions.dart';
import 'package:cw_solana/solana_transaction_credentials.dart';
import 'package:cw_solana/solana_transaction_history.dart';
import 'package:cw_solana/solana_transaction_info.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:cw_solana/solana_wallet_addresses.dart';
import 'package:cw_solana/spl_token.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/metaplex.dart' as metaplex;
import 'package:solana/solana.dart';
import 'package:web3dart/crypto.dart';

part 'solana_wallet.g.dart';

class SolanaWallet = SolanaWalletBase with _$SolanaWallet;

abstract class SolanaWalletBase
    extends WalletBase<SolanaBalance, SolanaTransactionHistory, SolanaTransactionInfo> with Store {
  SolanaWalletBase({
    required WalletInfo walletInfo,
    String? mnemonic,
    String? privateKey,
    required String password,
    SolanaBalance? initialBalance,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _client = SolanaWalletClient(),
        walletAddresses = SolanaWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, SolanaBalance>.of(
            {CryptoCurrency.sol: initialBalance ?? SolanaBalance(BigInt.zero.toDouble())}),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = SolanaTransactionHistory(walletInfo: walletInfo, password: password);

    if (!CakeHive.isAdapterRegistered(SPLToken.typeId)) {
      CakeHive.registerAdapter(SPLTokenAdapter());
    }

    _sharedPrefs.complete(SharedPreferences.getInstance());
  }

  final String _password;
  final String? _mnemonic;
  final String? _hexPrivateKey;

  // The Solana WalletPair
  Ed25519HDKeyPair? _walletKeyPair;

  Ed25519HDKeyPair? get walletKeyPair => _walletKeyPair;

  // To access the privateKey bytes.
  Ed25519HDKeyPairData? _keyPairData;

  late SolanaWalletClient _client;

  Timer? _transactionsUpdateTimer;

  late final Box<SPLToken> splTokensBox;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, SolanaBalance> balance;

  Completer<SharedPreferences> _sharedPrefs = Completer();

  @override
  Ed25519HDKeyPairData get keys {
    if (_keyPairData == null) {
      return Ed25519HDKeyPairData([], publicKey: const Ed25519HDPublicKey([]));
    }

    return _keyPairData!;
  }

  @override
  String? get seed => _mnemonic;

  @override
  String get privateKey => HEX.encode(_keyPairData!.bytes);

  Future<void> init() async {
    final boxName = "${walletInfo.name.replaceAll(" ", "_")}_${SPLToken.boxName}";

    splTokensBox = await CakeHive.openBox<SPLToken>(boxName);

    // Create WalletPair using either the mnemonic or the privateKey
    _walletKeyPair = await getWalletPair(
      mnemonic: _mnemonic,
      privateKey: _hexPrivateKey,
    );

    // Extract the keyPairData containing both the privateKey bytes and the publicKey hex.
    _keyPairData = await _walletKeyPair!.extract();

    walletInfo.address = _walletKeyPair!.address;

    await walletAddresses.init();
    await transactionHistory.init();
    await save();
  }

  Future<Wallet> getWalletPair({String? mnemonic, String? privateKey}) async {
    assert(mnemonic != null || privateKey != null);

    if (privateKey != null) {
      final privateKeyBytes = hexToBytes(privateKey);
      return await Wallet.fromPrivateKeyBytes(privateKey: privateKeyBytes);
    }

    return Wallet.fromMnemonic(mnemonic!, account: 0, change: 0);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

  @override
  Future<void> changePassword(String password) => throw UnimplementedError("changePassword");

  @override
  void close() {
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
        throw Exception("Solana Node connection failed");
      }

      try {
        await Future.wait([
          _updateBalance(),
          _updateNativeSOLTransactions(),
          _updateSPLTokenTransactions(),
        ]);
      } catch (e) {
        log(e.toString());
      }

      _setTransactionUpdateTimer();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final solCredentials = credentials as SolanaTransactionCredentials;

    final outputs = solCredentials.outputs;

    final hasMultiDestination = outputs.length > 1;

    await _updateBalance();

    final CryptoCurrency transactionCurrency =
        balance.keys.firstWhere((element) => element.title == solCredentials.currency.title);

    final walletBalanceForCurrency = balance[transactionCurrency]!.balance;

    double totalAmount = 0.0;

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw SolanaTransactionWrongBalanceException(transactionCurrency);
      }

      final totalAmountFromCredentials =
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      totalAmount = totalAmountFromCredentials.toDouble();

      if (walletBalanceForCurrency < totalAmount) {
        throw SolanaTransactionWrongBalanceException(transactionCurrency);
      }
    } else {
      final output = outputs.first;

      final totalOriginalAmount = double.parse(output.cryptoAmount ?? '0.0');

      totalAmount = output.sendAll ? walletBalanceForCurrency : totalOriginalAmount;

      if (walletBalanceForCurrency < totalAmount) {
        throw SolanaTransactionWrongBalanceException(transactionCurrency);
      }
    }

    String? tokenMint;
    // Token Mint is only needed for transactions that are not native tokens(non-SOL transactions)
    if (transactionCurrency.title != CryptoCurrency.sol.title) {
      tokenMint = (transactionCurrency as SPLToken).mintAddress;
    }

    final pendingSolanaTransaction = await _client.signSolanaTransaction(
      tokenMint: tokenMint,
      tokenTitle: transactionCurrency.title,
      inputAmount: totalAmount,
      ownerKeypair: _walletKeyPair!,
      tokenDecimals: transactionCurrency.decimals,
      destinationAddress: solCredentials.outputs.first.isParsedAddress
          ? solCredentials.outputs.first.extractedAddress!
          : solCredentials.outputs.first.address,
    );

    return pendingSolanaTransaction;
  }

  @override
  Future<Map<String, SolanaTransactionInfo>> fetchTransactions() async => {};

  /// Fetches the native SOL transactions linked to the wallet Public Key
  Future<void> _updateNativeSOLTransactions() async {
    final address = Ed25519HDPublicKey.fromBase58(_walletKeyPair!.address);

    final transactions = await _client.fetchTransactions(address);

    final Map<String, SolanaTransactionInfo> result = {};

    for (var transactionModel in transactions) {
      result[transactionModel.id] = SolanaTransactionInfo(
        id: transactionModel.id,
        to: transactionModel.to,
        from: transactionModel.from,
        blockTime: transactionModel.blockTime,
        direction: transactionModel.isOutgoingTx
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        solAmount: transactionModel.amount,
        isPending: false,
        txFee: transactionModel.fee,
        tokenSymbol: transactionModel.tokenSymbol,
      );
    }

    transactionHistory.addMany(result);

    await transactionHistory.save();
  }

  /// Fetches the SPL Tokens transactions linked to the token account Public Key
  Future<void> _updateSPLTokenTransactions() async {
    List<SolanaTransactionModel> splTokenTransactions = [];

    for (var token in balance.keys) {
      if (token is SPLToken) {
        final tokenTxs = await _client.getSPLTokenTransfers(
          token.mintAddress,
          token.symbol,
          token.decimal,
          _walletKeyPair!,
        );

        splTokenTransactions.addAll(tokenTxs);
      }
    }

    final Map<String, SolanaTransactionInfo> result = {};

    for (var transactionModel in splTokenTransactions) {
      result[transactionModel.id] = SolanaTransactionInfo(
        id: transactionModel.id,
        to: transactionModel.to,
        from: transactionModel.from,
        blockTime: transactionModel.blockTime,
        direction: transactionModel.isOutgoingTx
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        solAmount: transactionModel.amount,
        isPending: false,
        txFee: transactionModel.fee,
        tokenSymbol: transactionModel.tokenSymbol,
      );
    }

    transactionHistory.addMany(result);

    await transactionHistory.save();
  }

  @override
  Future<void> rescan({required int height}) => throw UnimplementedError("rescan");

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      await Future.wait([
        _updateBalance(),
        _updateNativeSOLTransactions(),
        _updateSPLTokenTransactions(),
      ]);

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'private_key': privateKey,
        'balance': balance[currency]!.toJSON(),
      });

  static Future<SolanaWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String?;
    final privateKey = data['private_key'] as String?;
    final balance = SolanaBalance.fromJSON(data['balance'] as String) ?? SolanaBalance(0.0);

    return SolanaWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      privateKey: privateKey,
      initialBalance: balance,
    );
  }

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchSOLBalance();
    await _fetchSPLTokensBalances();
    await save();
  }

  Future<SolanaBalance> _fetchSOLBalance() async {
    final balance = await _client.getBalance(_walletKeyPair!.address);

    return SolanaBalance(balance);
  }

  Future<void> _fetchSPLTokensBalances() async {
    for (var token in splTokensBox.values) {
      if (token.enabled) {
        try {
          final tokenBalance =
              await _client.getSplTokenBalance(token.mintAddress, _walletKeyPair!.address) ??
                  balance[token] ??
                  SolanaBalance(0.0);
          balance[token] = tokenBalance;
        } catch (e) {
          print('Error fetching spl token (${token.symbol}) balance ${e.toString()}');
        }
      } else {
        balance.remove(token);
      }
    }
  }

  @override
  Future<void>? updateBalance() async => await _updateBalance();

  List<SPLToken> get splTokenCurrencies => splTokensBox.values.toList();

  void addInitialTokens() {
    final initialSPLTokens = DefaultSPLTokens().initialSPLTokens;

    for (var token in initialSPLTokens) {
      splTokensBox.put(token.mintAddress, token);
    }
  }

  Future<void> addSPLToken(SPLToken token) async {
    await splTokensBox.put(token.mintAddress, token);

    if (token.enabled) {
      final tokenBalance =
          await _client.getSplTokenBalance(token.mintAddress, _walletKeyPair!.address) ??
              balance[token] ??
              SolanaBalance(0.0);

      balance[token] = tokenBalance;
    } else {
      balance.remove(token);
    }
  }

  Future<void> deleteSPLToken(SPLToken token) async {
    await token.delete();

    balance.remove(token);
    _updateBalance();
  }

  Future<SPLToken?> getSPLToken(String mintAddress) async {
    // Convert SPL token mint address to public key
    final mintPublicKey = Ed25519HDPublicKey.fromBase58(mintAddress);

    // Fetch token's metadata account
    final token = await solanaClient!.rpcClient.getMetadata(mint: mintPublicKey);

    if (token == null) {
      return null;
    }

    return SPLToken.fromMetadata(
      name: token.name,
      mint: token.mint,
      symbol: token.symbol,
      mintAddress: mintAddress,
    );
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionsHistoryFileName');

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionsHistoryFileName');
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }

  void _setTransactionUpdateTimer() {
    if (_transactionsUpdateTimer?.isActive ?? false) {
      _transactionsUpdateTimer!.cancel();
    }

    _transactionsUpdateTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _updateSPLTokenTransactions();
      _updateNativeSOLTransactions();
      _updateBalance();
    });
  }

  Future<String> signSolanaMessage(String message) async {
    // Convert the message to bytes
    final messageBytes = utf8.encode(message);

    // Sign the message bytes with the wallet's private key
    final signature = await _walletKeyPair!.sign(messageBytes);

    // Convert the signature to a hexadecimal string
    final hex = bytesToHex(signature.bytes);

    return hex;
  }

  SolanaClient? get solanaClient => _client.getSolanaClient;
}
