import 'dart:async';
import 'dart:convert';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/homoglyph_normalizer.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_solana/default_spl_tokens.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_client.dart';
import 'package:cw_solana/solana_exceptions.dart';
import 'package:cw_solana/solana_transaction_credentials.dart';
import 'package:cw_solana/solana_transaction_history.dart';
import 'package:cw_solana/solana_transaction_info.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:cw_solana/solana_wallet_addresses.dart';
import 'package:cw_core/spl_token.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_chain/solana/solana.dart' hide Store;
import 'package:bip39/bip39.dart' as bip39;
import 'package:blockchain_utils/blockchain_utils.dart';

part 'solana_wallet.g.dart';

class SolanaWallet = SolanaWalletBase with _$SolanaWallet;

abstract class SolanaWalletBase
    extends WalletBase<SolanaBalance, SolanaTransactionHistory, SolanaTransactionInfo>
    with Store, WalletKeysFile {
  SolanaWalletBase({
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    String? mnemonic,
    String? privateKey,
    required String password,
    SolanaBalance? initialBalance,
    required this.encryptionFileUtils,
    this.passphrase,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _client = SolanaWalletClient(),
        walletAddresses = SolanaWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, SolanaBalance>.of(
            {CryptoCurrency.sol: initialBalance ?? SolanaBalance.zero(CryptoCurrency.sol)}),
        super(walletInfo, derivationInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = SolanaTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );

    if (!CakeHive.isAdapterRegistered(SPLToken.typeId)) {
      CakeHive.registerAdapter(SPLTokenAdapter());
    }

    _sharedPrefs.complete(SharedPreferences.getInstance());
  }

  final String _password;
  final String? _mnemonic;
  final String? _hexPrivateKey;
  final EncryptionFileUtils encryptionFileUtils;

  late final SolanaWalletClient _client;

  SolanaWalletClient get client => _client;

  @observable
  Money? estimatedFee;

  Timer? _transactionsUpdateTimer;

  Future<void>? _currentRefresh;

  late final Box<SPLToken> splTokensBox;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, SolanaBalance> balance =
      ObservableMap<CryptoCurrency, SolanaBalance>();

  final Completer<SharedPreferences> _sharedPrefs = Completer();

  @override
  Object get keys => throw UnimplementedError("keys");

  late final SolanaPrivateKey _solanaPrivateKey;

  late final SolanaPublicKey _solanaPublicKey;

  SolanaPublicKey get solanaPublicKey => _solanaPublicKey;

  SolanaPrivateKey get solanaPrivateKey => _solanaPrivateKey;

  String get solanaAddress => _solanaPublicKey.toAddress().address;

  @override
  String? get seed => _mnemonic;

  @override
  String get privateKey => _solanaPrivateKey.seedHex();

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: _mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
      );

  Future<void> init() async {
    final boxName = "${walletInfo.name.replaceAll(" ", "_")}_${SPLToken.boxName}";

    splTokensBox = await CakeHive.openBox<SPLToken>(boxName);

    await _checkForExistingScamTokens();

    // Create the privatekey using either the mnemonic or the privateKey
    _solanaPrivateKey = await getPrivateKey(
      mnemonic: _mnemonic,
      privateKey: _hexPrivateKey,
      passphrase: passphrase,
    );

    // Extract the public key and wallet address
    _solanaPublicKey = _solanaPrivateKey.publicKey();

    walletInfo.address = _solanaPublicKey.toAddress().address;

    await walletAddresses.init();
    await transactionHistory.init();

    await save();
  }

  String get _scamCheckDoneKey => 'solana_scam_check_v2_done_${walletInfo.name}';

  Future<void> _checkForExistingScamTokens() async {
    if (!splTokensBox.isOpen) return;

    final prefs = await _sharedPrefs.future;
    if (prefs.getBool(_scamCheckDoneKey) == true) return;

    final defaultMints = DefaultSPLTokens().initialSPLTokens.map((t) => t.mintAddress).toSet();
    final defaultSymbolsUpper =
        DefaultSPLTokens().initialSPLTokens.map((t) => t.symbol.toUpperCase()).toSet();

    for (final token in splTokensBox.values) {
      final suspicious = isTokenPropertiesSuspicious(
        token,
        cachedDefaultMints: defaultMints,
        cachedDefaultSymbolsUpper: defaultSymbolsUpper,
      );
      if (suspicious && !token.isPotentialScam) {
        token.isPotentialScam = true;
        await token.save();
      }
    }

    await prefs.setBool(_scamCheckDoneKey, true);
  }

  Future<SolanaPrivateKey> getPrivateKey({
    String? mnemonic,
    String? privateKey,
    String? passphrase,
  }) async {
    assert(mnemonic != null || privateKey != null);

    if (mnemonic != null) {
      final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase ?? '');

      // Derive a Solana private key from the seed
      final bip44 = Bip44.fromSeed(seed, Bip44Coins.solana);

      final childKey = bip44.deriveDefaultPath.change(Bip44Changes.chainExt);

      return SolanaPrivateKey.fromSeed(childKey.privateKey.raw);
    }

    try {
      final keypairBytes = Base58Decoder.decode(privateKey!);
      return SolanaPrivateKey.fromBytes(keypairBytes);
    } catch (_) {
      final privateKeyBytes = HEX.decode(privateKey!);
      return SolanaPrivateKey.fromSeed(privateKeyBytes);
    }
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
        throw Exception("Solana Node connection failed");
      }

      _setTransactionUpdateTimer();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  Future<void> _getEstimatedFees() async {
    try {
      estimatedFee = await _client.getEstimatedFee(_solanaPublicKey, Commitment.confirmed);
    } catch (e) {
      estimatedFee = Money.zero(currency);
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final solCredentials = credentials as SolanaTransactionCredentials;

    final outputs = solCredentials.outputs;

    final hasMultiDestination = outputs.length > 1;

    await updateTokenBalance();

    final transactionCurrency = balance.keys.firstWhere(
        (currency) =>
            currency.title == credentials.currency.title &&
            currency.tag == credentials.currency.tag,
        orElse: () => throw Exception(
            'Currency ${credentials.currency.title} ${credentials.currency.tag} is not accessible in the wallet, try to enable it first.'));

    final walletBalanceForCurrency = balance[transactionCurrency]!.available;

    final solBalance = balance[CryptoCurrency.sol]!.available;

    var totalAmount = Money.zero(transactionCurrency);
    var isSendAll = false;

    if (hasMultiDestination) {
      // Solana doesn't have multi destination right now
      throw SolanaTransactionCreationException(transactionCurrency);
    } else {
      final output = outputs.first;

      isSendAll = output.sendAll;

      if (isSendAll) {
        totalAmount = walletBalanceForCurrency;
      } else {
        totalAmount = output.cryptoAmount.copyWith(currency: transactionCurrency);
      }

      if (walletBalanceForCurrency < totalAmount) {
        throw SolanaTransactionWrongBalanceException(transactionCurrency);
      }
    }

    String? tokenMint;
    // Token Mint is only needed for transactions that are not native tokens(non-SOL transactions)
    if (transactionCurrency.title != CryptoCurrency.sol.title) {
      tokenMint = (transactionCurrency as SPLToken).mintAddress;
    }

    return _client.signSolanaTransaction(
      tokenMint: tokenMint,
      inputAmount: totalAmount,
      ownerPrivateKey: _solanaPrivateKey,
      destinationAddress: solCredentials.outputs.first.isParsedAddress
          ? solCredentials.outputs.first.extractedAddress!
          : solCredentials.outputs.first.address,
      isSendAll: isSendAll,
      solBalance: solBalance,
    );
  }

  @override
  Future<Map<String, SolanaTransactionInfo>> fetchTransactions() async => {};

  @override
  Future<void> updateTransactionsHistory({List<String>? specificTokenMints}) async {
    await Future.wait([
      _updateNativeSOLTransactions(),
      updateSPLTokenTransactions(specificMints: specificTokenMints),
    ]);
  }

  static const _nativeSource = 'native';

  String _lastSyncedSignatureKey(String source) =>
      'solana_last_synced_signature_${walletInfo.name}_$source';

  Future<String?> _lastSyncedSignature(String source) async {
    if (transactionHistory.transactions.isEmpty) return null;

    final prefs = await _sharedPrefs.future;

    return prefs.getString(_lastSyncedSignatureKey(source));
  }

  Future<void> _saveLastSyncedSignature(String source, String? signature) async {
    if (signature == null) return;

    final prefs = await _sharedPrefs.future;

    await prefs.setString(_lastSyncedSignatureKey(source), signature);
  }

  Future<void> _clearLastSyncedSignature(String source) async {
    final prefs = await _sharedPrefs.future;

    await prefs.remove(_lastSyncedSignatureKey(source));
  }

  /// Polls for a specific transaction by signature with exponential backoff
  /// I'm using this in case we make the call to fetch the transaction and it has not finished its confirmations on the solana network and been indexed by the node networks we use.
  Future<void> pollForTransaction({
    required String signature,
    Duration initialDelay = const Duration(seconds: 1),
    int maxRetries = 5,
  }) async {
    final walletAddress = _solanaPublicKey.toAddress().address;

    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(initialDelay * (i + 1));

      try {
        final result = await _client.fetchTransactionBySignature(
          signature: signature,
          walletAddress: walletAddress,
        );

        if (result != null && result.transactions.isNotEmpty) {
          await addTransactionsToTransactionHistory(result.transactions);

          // Update only the tokens involved in this transaction
          if (result.tokenMints.isNotEmpty) {
            await Future.wait([
              updateSPLTokenTransactions(specificMints: result.tokenMints),
              updateTokenBalance(tokenMints: result.tokenMints),
            ]);
          } else {
            // If no token mints, still update SOL balance
            await updateTokenBalance(tokenMints: []);
          }

          return;
        }
      } catch (e) {
        printV('Error polling for transaction (attempt ${i + 1}/$maxRetries): $e');
      }
    }

    // Fallback to full refresh if not found after max retries
    printV('Transaction not found after $maxRetries attempts, falling back to full refresh');
    await updateTransactionsHistory();
  }

  void updateTransactions(List<SolanaTransactionModel> updatedTx) => _addTransactions(updatedTx);

  /// Fetches the native SOL transactions linked to the wallet Public Key
  Future<void> _updateNativeSOLTransactions() async {
    final result = await _client.fetchTransactions(
      _solanaPublicKey.toAddress(),
      untilSignature: await _lastSyncedSignature(_nativeSource),
      onUpdate: updateTransactions,
    );

    await _updateStateWhenSyncForTheSourceEnds(_nativeSource, result);
  }

  Future<void> _updateStateWhenSyncForTheSourceEnds(
    String source,
    TransactionSyncResult result,
  ) async {
    if (result.transactions.isNotEmpty) {
      final isSaved = await transactionHistory.saveAndConfirm();

      if (!isSaved) return;
    }

    await _saveLastSyncedSignature(source, result.newestSignature);
  }

  Future<void> updateSPLTokenTransactions({List<String>? specificMints}) async {
    final allTokens = splTokensBox.values.where((t) => t.enabled).toList(growable: false);

    // Filter to specific mints if provided
    final tokens = specificMints != null
        ? allTokens.where((t) => specificMints.contains(t.mintAddress)).toList(growable: false)
        : allTokens;

    if (tokens.isEmpty) return;

    const int batchSize = 5;

    for (var i = 0; i < tokens.length; i += batchSize) {
      final batch = tokens.sublist(
        i,
        i + batchSize > tokens.length ? tokens.length : i + batchSize,
      );

      await Future.wait(
        batch.map((token) async {
          try {
            final result = await _client.getSPLTokenTransfers(
              mintAddress: token.mintAddress,
              splToken: token,
              privateKey: _solanaPrivateKey,
              untilSignature: await _lastSyncedSignature(token.mintAddress),
              onUpdate: updateTransactions,
            );

            await _updateStateWhenSyncForTheSourceEnds(token.mintAddress, result);
          } catch (e) {
            printV('Error fetching spl token (${token.symbol}) transfers ${e.toString()}');
          }
        }),
      );
    }
  }

  void _addTransactions(List<SolanaTransactionModel> transactions) {
    final Map<String, SolanaTransactionInfo> result = {};

    for (var transactionModel in transactions) {
      result[transactionModel.id] = SolanaTransactionInfo(
        id: transactionModel.id,
        to: transactionModel.to,
        from: transactionModel.from,
        date: transactionModel.blockTime,
        direction: transactionModel.isOutgoingTx
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        amount: transactionModel.amount,
        isPending: false,
        fee: transactionModel.fee,
      );
    }

    transactionHistory.addMany(result);
  }

  Future<void> addTransactionsToTransactionHistory(
    List<SolanaTransactionModel> transactions,
  ) async {
    _addTransactions(transactions);

    await transactionHistory.save();
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

  // we want to handle the case where multiple refresh triggers (our users can swipe down
  // multiple times), so we track the currrent refresh and join it instead of starting
  // another one
  Future<void> _refresh() {
    return _currentRefresh ??= Future.wait([
      updateTokenBalance(),
      updateTransactionsHistory(),
      _getEstimatedFees(),
    ]).whenComplete(() => _currentRefresh = null);
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      // Verify node health before attempting to sync
      final isHealthy = await checkNodeHealth();
      if (!isHealthy) {
        syncStatus = FailedSyncStatus();
        return;
      }

      await _refresh();

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'private_key': _hexPrivateKey,
        'balance': balance[currency]!.toJSON(),
        'passphrase': passphrase,
      });

  static Future<SolanaWallet> open({
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

    final balance = SolanaBalance.fromJSON(data?['balance'] as String?, CryptoCurrency.sol) ??
        SolanaBalance.zero(CryptoCurrency.sol);

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to then new .keys file scheme
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

    return SolanaWallet(
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

  Future<void> updateTokenBalance({List<String>? tokenMints}) async {
    // Fetch SOL and SPL token balances in parallel for better performance
    await Future.wait([
      _fetchSOLBalance().then((solBalance) {
        balance[CryptoCurrency.sol] = solBalance;
      }),
      _updateSplTokenBalancesInternal(tokenMints: tokenMints),
    ]);

    await save();
  }

  Future<SolanaBalance> _fetchSOLBalance() async {
    final balance = await _client.getBalance(solanaAddress);

    return SolanaBalance(balance);
  }

  /// Internal helper to update SPL token balances.
  /// When [tokenMints] is null or empty, updates all enabled tokens.
  Future<void> _updateSplTokenBalancesInternal({
    List<String>? tokenMints,
  }) async {
    // Remove disabled tokens first to keep state clean
    for (var token in splTokensBox.values.where((t) => !t.enabled)) {
      balance.remove(token);
    }

    final enabledTokens = splTokensBox.values.where((t) => t.enabled).toList(growable: false);
    if (enabledTokens.isEmpty) return;

    final tokens = tokenMints == null || tokenMints.isEmpty
        ? enabledTokens
        : enabledTokens.where((t) => tokenMints.contains(t.mintAddress)).toList(growable: false);

    if (tokens.isEmpty) return;

    const int batchSize = 5;

    for (var i = 0; i < tokens.length; i += batchSize) {
      final batch = tokens.sublist(
        i,
        i + batchSize > tokens.length ? tokens.length : i + batchSize,
      );

      final results = await Future.wait(batch.map((token) async {
        try {
          final fetched = await _client.getSplTokenBalance(token, solanaAddress);
          return MapEntry(token, fetched);
        } catch (e) {
          printV('Error fetching spl token (${token.symbol}) balance ${e.toString()}');
          return MapEntry<SPLToken, SolanaBalance?>(token, null);
        }
      }));

      for (final entry in results) {
        final token = entry.key;
        final fetchedBalance = entry.value;
        final currentBalance = balance[token] ?? SolanaBalance.zero(token);
        balance[token] = fetchedBalance ?? currentBalance;
      }
    }
  }

  @override
  Future<void>? updateBalance() async => await updateTokenBalance();

  @override
  Future<bool> checkNodeHealth() async {
    try {
      // Check native balance
      await _client.getBalance(solanaAddress, throwOnError: true);

      // Check USDC token balance
      final usdcMintAddress = DefaultSPLTokens().usdc;
      await _client.getSplTokenBalance(usdcMintAddress, solanaAddress, throwOnError: true);

      return true;
    } catch (e) {
      return false;
    }
  }

  List<SPLToken> get splTokenCurrencies => splTokensBox.values.toList();

  SPLToken? splTokenBySymbol(String symbol) {
    for (final token in splTokensBox.values) {
      if (token.symbol == symbol) return token;
    }

    return null;
  }

  void addInitialTokens() {
    final initialSPLTokens = DefaultSPLTokens().initialSPLTokens;

    for (var token in initialSPLTokens) {
      if (!splTokensBox.containsKey(token.mintAddress)) {
        splTokensBox.put(token.mintAddress, token);
      } else {
        // update existing token
        final existingToken = splTokensBox.get(token.mintAddress);
        splTokensBox.put(
            token.mintAddress, SPLToken.copyWith(token, enabled: existingToken!.enabled));
      }
    }
  }

  Future<SolanaMoralisDiscoveryResult> discoverTokensFromMoralis() async {
    try {
      if (!splTokensBox.isOpen) return SolanaMoralisDiscoveryResult.empty;

      final address = walletAddresses.address;
      if (address.isEmpty) return SolanaMoralisDiscoveryResult.empty;

      final walletTokens = await _client.fetchWalletTokensFromMoralis(address);
      if (walletTokens.isEmpty) return SolanaMoralisDiscoveryResult.empty;

      final existingMints = {
        for (final token in splTokensBox.values) token.mintAddress: token,
      };

      final defaultMints = DefaultSPLTokens().initialSPLTokens.map((t) => t.mintAddress).toSet();

      final newTokens = <DiscoveredSPLToken>[];

      for (final moralisToken in walletTokens) {
        final mint = moralisToken.mint;

        final existingToken = existingMints[mint];
        if (existingToken != null) {
          if (defaultMints.contains(mint) && !existingToken.enabled) {
            existingToken.enabled = true;
            await existingToken.save();
            await addSPLToken(existingToken);
          }
          continue;
        }

        final tokenInfo = await _client.fetchSPLTokenInfo(mint);
        if (tokenInfo == null) continue;

        final discoveredToken = SPLToken(
          name: tokenInfo.name,
          symbol: tokenInfo.symbol,
          mintAddress: mint,
          decimal: moralisToken.decimals,
          mint: tokenInfo.mint,
          iconPath: tokenInfo.iconPath,
          tag: 'SOL',
        );

        newTokens.add(
          DiscoveredSPLToken(
            token: discoveredToken,
            balance: moralisToken.amount,
          ),
        );
      }

      return SolanaMoralisDiscoveryResult(newTokens: newTokens);
    } catch (e) {
      printV('Error discovering SPL tokens from Moralis: ${e.toString()}');
      return SolanaMoralisDiscoveryResult.empty;
    }
  }

  static const _urlLikeSuspiciousMarkers = [
    't.me',
    '.me',
    'telegram',
    'http',
    'https',
    '.com',
    '.org',
    '.top',
    '.live',
    '.xyz',
    'www',
    '🎁',
    'airdrop',
    'distribution',
  ];

  static final _suspiciousWordPattern = RegExp(r'\b(bot|claim|reward)\b', caseSensitive: false);

  static const _knownNonSolanaNativeSymbols = {
    'BTC',
    'ETH',
    'BNB',
    'AVAX',
    'MATIC',
    'POL',
    'ICP',
    'TRX',
    'ATOM',
    'DOT',
    'ADA',
    'XRP',
    'XLM',
    'XMR',
    'ALGO',
    'NEAR',
    'TON',
    'HBAR',
    'APT',
    'SUI',
    'KAS',
  };

  static bool _hasSuspiciousData(String normalized) {
    final lower = normalized.toLowerCase();
    if (_urlLikeSuspiciousMarkers.any(lower.contains)) return true;
    return _suspiciousWordPattern.hasMatch(lower);
  }

  bool isTokenPropertiesSuspicious(
    SPLToken token, {
    Set<String>? cachedDefaultMints,
    Set<String>? cachedDefaultSymbolsUpper,
  }) {
    final defaultMints =
        cachedDefaultMints ?? DefaultSPLTokens().initialSPLTokens.map((t) => t.mintAddress).toSet();
    final defaultSymbolsUpper = cachedDefaultSymbolsUpper ??
        DefaultSPLTokens().initialSPLTokens.map((t) => t.symbol.toUpperCase()).toSet();

    final isTokenWhitelisted = defaultMints.contains(token.mintAddress);

    final normalizedName = normalizeHomoglyphs(token.name.trim().toUpperCase());
    final normalizedSymbol = normalizeHomoglyphs(token.symbol.trim().toUpperCase());
    final normalizedTitle = normalizeHomoglyphs(token.title.trim().toUpperCase());

    final hasSuspiciousData = _hasSuspiciousData(normalizedName) ||
        _hasSuspiciousData(normalizedSymbol) ||
        _hasSuspiciousData(normalizedTitle);

    const nativeSymbol = 'SOL';
    final hasSuspiciousNativeSymbol = normalizedSymbol == nativeSymbol && !isTokenWhitelisted;

    final hasSuspiciousDefaultTokenSymbol =
        defaultSymbolsUpper.contains(normalizedSymbol) && !isTokenWhitelisted;

    final hasSuspiciousNonSolanaNativeSymbol =
        _knownNonSolanaNativeSymbols.contains(normalizedSymbol) && !isTokenWhitelisted;

    return hasSuspiciousData ||
        hasSuspiciousNativeSymbol ||
        hasSuspiciousDefaultTokenSymbol ||
        hasSuspiciousNonSolanaNativeSymbol;
  }

  Future<void> addSPLToken(SPLToken token) async {
    final isSuspicious = isTokenPropertiesSuspicious(token);
    token.isPotentialScam = token.isPotentialScam || isSuspicious;

    await splTokensBox.put(token.mintAddress, token);

    if (token.enabled) {
      final tokenBalance = await _client.getSplTokenBalance(token, solanaAddress) ??
          balance[token] ??
          SolanaBalance.zero(token);

      balance[token] = tokenBalance;
    } else {
      balance.remove(token);
    }
  }

  Future<void> deleteSPLToken(SPLToken token) async {
    final sources = <String>{token.mintAddress};

    if (token.symbol == CryptoCurrency.sol.symbol) {
      sources.add(_nativeSource);
    }

    if (splTokensBox.isOpen) {
      sources.addAll(splTokensBox.values
          .where((t) => t.symbol == token.symbol)
          .map((t) => t.mintAddress));

      await splTokensBox.delete(token.mintAddress);
    }

    balance.remove(token);
    await _removeTokenTransactionsInHistory(token);

    for (final source in sources) {
      await _clearLastSyncedSignature(source);
    }

    updateTokenBalance();
  }

  Future<void> _removeTokenTransactionsInHistory(SPLToken token) async {
    transactionHistory.transactions
        .removeWhere((key, value) => value.amount.currency.symbol == token.symbol);
    await transactionHistory.save();
  }

  Future<SPLToken?> getSPLToken(String mintAddress) async {
    try {
      return await _client.fetchSPLTokenInfo(mintAddress);
    } catch (e, s) {
      printV('Error fetching token: ${e.toString()}, ${s.toString()}');
      return null;
    }
  }

  Future<bool?> isTokenVerifiedOnJupiter(String mintAddress) =>
      _client.isTokenVerifiedOnJupiter(mintAddress);

  void _setTransactionUpdateTimer() {
    if (_transactionsUpdateTimer?.isActive ?? false) {
      _transactionsUpdateTimer!.cancel();
    }

    _transactionsUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await _refresh();
      } catch (e) {
        printV('Error on periodic solana refresh: $e');
      }
    });
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    // Convert the message to bytes
    final messageBytes = utf8.encode(message);

    // Sign the message bytes with the wallet's private key
    final signature = (_solanaPrivateKey.sign(messageBytes));

    return Base58Encoder.encode(signature);
  }

  List<List<int>> bytesFromSigString(String signatureString) {
    final regex = RegExp(r'Signature\(\[(.+)\], publicKey: (.+)\)');
    final match = regex.firstMatch(signatureString);

    if (match != null) {
      final bytesString = match.group(1)!;
      final base58EncodedPublicKeyString = match.group(2)!;
      final sigBytes = bytesString.split(', ').map(int.parse).toList();

      List<int> pubKeyBytes = SolAddrDecoder().decodeAddr(base58EncodedPublicKeyString);

      return [sigBytes, pubKeyBytes];
    } else {
      throw const FormatException('Invalid Signature string format');
    }
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    String signatureString = utf8.decode(HEX.decode(signature));

    List<List<int>> bytes = bytesFromSigString(signatureString);

    final messageBytes = utf8.encode(message);
    final sigBytes = bytes[0];
    final pubKeyBytes = bytes[1];

    if (address == null) {
      return false;
    }

    // make sure the address derived from the public key provided matches the one we expect
    final pub = SolanaPublicKey.fromBytes(pubKeyBytes);
    if (address != pub.toAddress().address) {
      return false;
    }

    return pub.verify(
      message: messageBytes,
      signature: sigBytes,
    );
  }

  SolanaRPC? get solanaProvider => _client.getSolanaProvider;

  @override
  String get password => _password;

  @override
  final String? passphrase;
}

class DiscoveredSPLToken {
  final SPLToken token;
  final double balance;

  const DiscoveredSPLToken({
    required this.token,
    required this.balance,
  });
}

class SolanaMoralisDiscoveryResult {
  final List<DiscoveredSPLToken> newTokens;

  const SolanaMoralisDiscoveryResult({required this.newTokens});

  static const SolanaMoralisDiscoveryResult empty = SolanaMoralisDiscoveryResult(newTokens: []);
}
