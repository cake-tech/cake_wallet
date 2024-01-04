import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_evm/default_evm_chain_erc20_tokens.dart';
import 'package:cw_evm/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_formatter.dart';
import 'package:cw_evm/evm_chain_transaction_credentials.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet_addresses.dart';
import 'package:cw_evm/file.dart';
import 'package:hive/hive.dart';
import 'package:hex/hex.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

import 'evm_erc20_balance.dart';
import 'evm_chain_transaction_info.dart';

part 'evm_chain_wallet.g.dart';

class EVMChainWallet = EVMChainWalletBase with _$EVMChainWallet;

abstract class EVMChainWalletBase
    extends WalletBase<EVMChainERC20Balance, EVMChainTransactionHistory, EVMChainTransactionInfo>
    with Store {
  EVMChainWalletBase({
    required WalletInfo walletInfo,
    required CryptoCurrency nativeCurrency,
    String? mnemonic,
    String? privateKey,
    required String password,
    EVMChainERC20Balance? initialBalance,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _isTransactionUpdating = false,
        _client = EVMChainClient(),
        walletAddresses = EVMChainWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, EVMChainERC20Balance>.of(
          {
            // Not sure of this yet, will it work? will it not?
            nativeCurrency: initialBalance ?? EVMChainERC20Balance(BigInt.zero),
          },
        ),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = EVMChainTransactionHistory(walletInfo: walletInfo, password: password);

    if (!CakeHive.isAdapterRegistered(Erc20Token.typeId)) {
      CakeHive.registerAdapter(Erc20TokenAdapter());
    }

    sharedPrefs.complete(SharedPreferences.getInstance());
  }

  final String? _mnemonic;
  final String? _hexPrivateKey;
  final String _password;

  late final Box<Erc20Token> erc20TokensBox;

  late final Box<Erc20Token> evmChainErc20TokensBox;

  late final EthPrivateKey _evmChainPrivateKey;

  EthPrivateKey get evmChainPrivateKey => _evmChainPrivateKey;

  late EVMChainClient _client;

  int? _gasPrice;
  int? _estimatedGas;
  bool _isTransactionUpdating;

  // TODO: remove after integrating our own node and having eth_newPendingTransactionFilter
  Timer? _transactionsUpdateTimer;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, EVMChainERC20Balance> balance;

  Completer<SharedPreferences> sharedPrefs = Completer();

  Future<void> init() async {
    await initErc20TokensBox();

    await walletAddresses.init();
    await transactionHistory.init();
    _evmChainPrivateKey = await getPrivateKey(
      mnemonic: _mnemonic,
      privateKey: _hexPrivateKey,
      password: _password,
    );
    walletAddresses.address = _evmChainPrivateKey.address.toString();
    await save();
  }

  Future<void> initErc20TokensBox() async {
    // This is for ethereum wallets,
    // Other wallets would override and initialize their respective boxes with their boxNames.
    await movePreviousErc20BoxConfigsToNewBox();
  }

  /// Majorly for backward compatibility for previous configs that have been set.
  Future<void> movePreviousErc20BoxConfigsToNewBox() async {
    // Opens a box specific to this wallet
    evmChainErc20TokensBox = await CakeHive.openBox<Erc20Token>(
        "${walletInfo.name.replaceAll(" ", "_")}_${Erc20Token.ethereumBoxName}");

    //Open the previous token configs box
    erc20TokensBox = await CakeHive.openBox<Erc20Token>(Erc20Token.boxName);

    // Check if it's empty, if it is, we stop the flow and return.
    if (erc20TokensBox.isEmpty) {
      // If it's empty, but the new wallet specific box is also empty,
      // we load the initial tokens to the new box.
      if (evmChainErc20TokensBox.isEmpty) addInitialTokens();
      return;
    }

    final allValues = erc20TokensBox.values.toList();

    // Clear and delete the old token box
    await erc20TokensBox.clear();
    await erc20TokensBox.deleteFromDisk();

    // Add all the previous tokens with configs to the new box
    evmChainErc20TokensBox.addAll(allValues);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    try {
      if (priority is EVMChainTransactionPriority) {
        final priorityFee = EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();
        return (_gasPrice! + priorityFee) * (_estimatedGas ?? 0);
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError("changePassword");
  }

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
        throw Exception("${walletInfo.type.name.toUpperCase()} Node connection failed");
      }

      _client.setListeners(_evmChainPrivateKey.address, _onNewTransaction);

      _setTransactionUpdateTimer();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as EVMChainTransactionCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;

    final CryptoCurrency transactionCurrency =
        balance.keys.firstWhere((element) => element.title == _credentials.currency.title);

    final _erc20Balance = balance[transactionCurrency]!;
    BigInt totalAmount = BigInt.zero;
    int exponent = transactionCurrency is Erc20Token ? transactionCurrency.decimal : 18;
    num amountToEVMChainMultiplier = pow(10, exponent);

    // so far this can not be made with Ethereum as Ethereum does not support multiple recipients
    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }

      final totalOriginalAmount = EVMChainFormatter.parseEVMChainAmountToDouble(
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0)));
      totalAmount = BigInt.from(totalOriginalAmount * amountToEVMChainMultiplier);

      if (_erc20Balance.balance < totalAmount) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }
    } else {
      final output = outputs.first;
      // since the fees are taken from Ethereum
      // then no need to subtract the fees from the amount if send all
      final BigInt allAmount;
      if (transactionCurrency is Erc20Token) {
        allAmount = _erc20Balance.balance;
      } else {
        allAmount = _erc20Balance.balance -
            BigInt.from(calculateEstimatedFee(_credentials.priority!, null));
      }
      final totalOriginalAmount =
          EVMChainFormatter.parseEVMChainAmountToDouble(output.formattedCryptoAmount ?? 0);
      totalAmount = output.sendAll
          ? allAmount
          : BigInt.from(totalOriginalAmount * amountToEVMChainMultiplier);

      if (_erc20Balance.balance < totalAmount) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }
    }

    final pendingEVMChainTransaction = await _client.signTransaction(
      privateKey: _evmChainPrivateKey,
      toAddress: _credentials.outputs.first.isParsedAddress
          ? _credentials.outputs.first.extractedAddress!
          : _credentials.outputs.first.address,
      amount: totalAmount.toString(),
      gas: _estimatedGas!,
      priority: _credentials.priority!,
      currency: transactionCurrency,
      exponent: exponent,
      contractAddress:
          transactionCurrency is Erc20Token ? transactionCurrency.contractAddress : null,
    );

    return pendingEVMChainTransaction;
  }

  Future<void> _updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      final isProviderEnabled = await checkIfScanProviderIsEnabled();

      if (!isProviderEnabled) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (_) {
      _isTransactionUpdating = false;
    }
  }

  Future<bool> checkIfScanProviderIsEnabled() async {
    bool isEtherscanEnabled = (await sharedPrefs.future).getBool("use_etherscan") ?? true;
    return isEtherscanEnabled;
  }

  @override
  Future<Map<String, EVMChainTransactionInfo>> fetchTransactions() async {
    final address = _evmChainPrivateKey.address.hex;
    final transactions = await _client.fetchTransactions(address);

    final List<Future<List<EVMChainTransactionModel>>> erc20TokensTransactions = [];

    for (var token in balance.keys) {
      if (token is Erc20Token) {
        erc20TokensTransactions.add(_client.fetchTransactions(
          address,
          contractAddress: token.contractAddress,
        ));
      }
    }

    final tokensTransaction = await Future.wait(erc20TokensTransactions);
    transactions.addAll(tokensTransaction.expand((element) => element));

    final Map<String, EVMChainTransactionInfo> result = {};

    for (var transactionModel in transactions) {
      if (transactionModel.isError) {
        continue;
      }

      result[transactionModel.hash] = EVMChainTransactionInfo(
        id: transactionModel.hash,
        height: transactionModel.blockNumber,
        ethAmount: transactionModel.amount,
        direction: transactionModel.from == address
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        isPending: false,
        date: transactionModel.date,
        confirmations: transactionModel.confirmations,
        ethFee: BigInt.from(transactionModel.gasUsed) * transactionModel.gasPrice,
        exponent: transactionModel.tokenDecimal ?? 18,
        tokenSymbol: transactionModel.tokenSymbol ?? "ETH",
        to: transactionModel.to,
      );
    }

    return result;
  }

  @override
  Object get keys => throw UnimplementedError("keys");

  @override
  Future<void> rescan({required int height}) {
    throw UnimplementedError("rescan");
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  String? get seed => _mnemonic;

  @override
  String get privateKey => HEX.encode(_evmChainPrivateKey.privateKey);

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await _updateBalance();
      await _updateTransactions();
      _gasPrice = await _client.getGasUnitPrice();
      _estimatedGas = await _client.getEstimatedGas();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _gasPrice = await _client.getGasUnitPrice());
      Timer.periodic(const Duration(seconds: 10),
          (timer) async => _estimatedGas = await _client.getEstimatedGas());

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

  static Future<EVMChainWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String?;
    final privateKey = data['private_key'] as String?;
    final balance = EVMChainERC20Balance.fromJSON(data['balance'] as String) ??
        EVMChainERC20Balance(BigInt.zero);

    final nativeCurrency = currencyForWalletType(walletInfo.type);

    return EVMChainWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      privateKey: privateKey,
      initialBalance: balance,
      nativeCurrency: nativeCurrency,
    );
  }

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchEVMChainBalance();

    await _fetchErc20Balances();
    await save();
  }

  Future<EVMChainERC20Balance> _fetchEVMChainBalance() async {
    final balance = await _client.getBalance(_evmChainPrivateKey.address);
    return EVMChainERC20Balance(balance.getInWei);
  }

  Future<void> _fetchErc20Balances() async {
    for (var token in evmChainErc20TokensBox.values) {
      try {
        if (token.enabled) {
          balance[token] = await _client.fetchERC20Balances(
            _evmChainPrivateKey.address,
            token.contractAddress,
          );
        } else {
          balance.remove(token);
        }
      } catch (_) {}
    }
  }

  Future<EthPrivateKey> getPrivateKey(
      {String? mnemonic, String? privateKey, required String password}) async {
    assert(mnemonic != null || privateKey != null);

    if (privateKey != null) {
      return EthPrivateKey.fromHex(privateKey);
    }

    final seed = bip39.mnemonicToSeed(mnemonic!);

    final root = bip32.BIP32.fromSeed(seed);

    const hdPathEVMChain = "m/44'/60'/0'/0";
    const index = 0;
    final addressAtIndex = root.derivePath("$hdPathEVMChain/$index");

    return EthPrivateKey.fromHex(HEX.encode(addressAtIndex.privateKey as List<int>));
  }

  Future<void>? updateBalance() async => await _updateBalance();

  List<Erc20Token> get erc20Currencies => evmChainErc20TokensBox.values.toList();

  Future<void> addErc20Token(Erc20Token token) async {
    String? iconPath;
    try {
      iconPath = CryptoCurrency.all
          .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
          .iconPath;
    } catch (_) {}

    final _token = Erc20Token(
      name: token.name,
      symbol: token.symbol,
      contractAddress: token.contractAddress,
      decimal: token.decimal,
      enabled: token.enabled,
      tag: token.tag ?? "ETH",
      iconPath: iconPath,
    );

    await evmChainErc20TokensBox.put(_token.contractAddress, _token);

    if (_token.enabled) {
      balance[_token] = await _client.fetchERC20Balances(
        _evmChainPrivateKey.address,
        _token.contractAddress,
      );
    } else {
      balance.remove(_token);
    }
  }

  Future<void> deleteErc20Token(Erc20Token token) async {
    await token.delete();

    balance.remove(token);
    _updateBalance();
  }

  Future<Erc20Token?> getErc20Token(String contractAddress) async =>
      await _client.getErc20Token(contractAddress);

  void _onNewTransaction() {
    _updateBalance();
    _updateTransactions();
  }

  void addInitialTokens() {
    final initialErc20Tokens = DefaultEVMChainErc20Tokens().initialErc20Tokens;

    for (var token in initialErc20Tokens) {
      evmChainErc20TokensBox.put(token.contractAddress, token);
    }
  }

  /// Returns the transaction history file name.
  ///
  /// Each wallet would override this to provide the path to it's own transaction history file.
  String getTransactionHistoryFileName() => 'transactions.json';

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final transactionHistoryFileNameForWallet = getTransactionHistoryFileName();

    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionHistoryFileNameForWallet');

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionHistoryFileNameForWallet');
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }

  void _setTransactionUpdateTimer() {
    if (_transactionsUpdateTimer?.isActive ?? false) {
      _transactionsUpdateTimer!.cancel();
    }

    _transactionsUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateTransactions();
      _updateBalance();
    });
  }

  /// Scan Providers:
  ///
  /// EtherScan for Ethereum.
  ///
  /// PolygonScan for Polygon.
  void updateScanProviderUsageState(bool isEnabled) {
    if (isEnabled) {
      _updateTransactions();
      _setTransactionUpdateTimer();
    } else {
      _transactionsUpdateTimer?.cancel();
    }
  }

  @override
  String signMessage(String message, {String? address}) =>
      bytesToHex(_evmChainPrivateKey.signPersonalMessageToUint8List(ascii.encode(message)));

  Web3Client? getWeb3Client() => _client.getWeb3Client();
}
