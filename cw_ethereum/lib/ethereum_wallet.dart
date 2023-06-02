import 'dart:async';
import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_ethereum/ethereum_balance.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_exceptions.dart';
import 'package:cw_ethereum/ethereum_transaction_credentials.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';
import 'package:cw_ethereum/ethereum_wallet_addresses.dart';
import 'package:cw_ethereum/file.dart';
import 'package:hex/hex.dart';
import 'package:mobx/mobx.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

part 'ethereum_wallet.g.dart';

class EthereumWallet = EthereumWalletBase with _$EthereumWallet;

abstract class EthereumWalletBase
    extends WalletBase<ERC20Balance, EthereumTransactionHistory, EthereumTransactionInfo>
    with Store {
  EthereumWalletBase({
    required WalletInfo walletInfo,
    required String mnemonic,
    required String password,
    ERC20Balance? initialBalance,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _priorityFees = [],
        _client = EthereumClient(),
        walletAddresses = EthereumWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, ERC20Balance>.of(
            {CryptoCurrency.eth: initialBalance ?? ERC20Balance(BigInt.zero)}),
        super(walletInfo) {
    this.walletInfo = walletInfo;
  }

  final String _mnemonic;
  final String _password;

  late final EthPrivateKey _privateKey;

  late EthereumClient _client;

  List<int> _priorityFees;
  int? _gasPrice;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, ERC20Balance> balance;

  Future<void> init() async {
    await walletAddresses.init();
    _privateKey = await getPrivateKey(_mnemonic, _password);
    transactionHistory = EthereumTransactionHistory();
    walletAddresses.address = _privateKey.address.toString();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    try {
      if (priority is EthereumTransactionPriority) {
        return _gasPrice! * _priorityFees[priority.raw];
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
  void close() {}

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final isConnected = _client.connect(node);

      if (!isConnected) {
        throw Exception("Ethereum Node connection failed");
      }

      _updateBalance();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as EthereumTransactionCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final _erc20Balance = balance[_credentials.currency]!;
    int totalAmount = 0;

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw EthereumTransactionCreationException();
      }

      totalAmount = outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      if (_erc20Balance.balance < EtherAmount.inWei(totalAmount as BigInt).getInWei) {
        throw EthereumTransactionCreationException();
      }
    } else {
      final output = outputs.first;
      final int allAmount = _erc20Balance.balance.toInt() - feeRate(_credentials.priority!);
      totalAmount = output.sendAll ? allAmount : output.formattedCryptoAmount ?? 0;

      if ((output.sendAll &&
              _erc20Balance.balance < EtherAmount.inWei(totalAmount as BigInt).getInWei) ||
          (!output.sendAll && _erc20Balance.balance.toInt() <= 0)) {
        throw EthereumTransactionCreationException();
      }
    }

    final pendingEthereumTransaction = await _client.signTransaction(
      privateKey: _privateKey,
      toAddress: _credentials.outputs.first.address,
      amount: totalAmount.toString(),
      gas: _priorityFees[_credentials.priority!.raw],
      priority: _credentials.priority!,
      currency: _credentials.currency,
    );

    return pendingEthereumTransaction;
  }

  @override
  Future<Map<String, EthereumTransactionInfo>> fetchTransactions() {
    throw UnimplementedError("fetchTransactions");
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
  String get seed => _mnemonic;

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await _updateBalance();
      _gasPrice = await _client.getGasUnitPrice();
      _priorityFees = await _client.getEstimatedGasForPriorities();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _gasPrice = await _client.getGasUnitPrice());
      Timer.periodic(const Duration(minutes: 1),
          (timer) async => _priorityFees = await _client.getEstimatedGasForPriorities());

      syncStatus = SyncedSyncStatus();
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  int feeRate(TransactionPriority priority) {
    try {
      if (priority is EthereumTransactionPriority) {
        return _priorityFees[priority.raw];
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'balance': balance[currency]!.toJSON(),
      });

  static Future<EthereumWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String;
    final balance = ERC20Balance.fromJSON(data['balance'] as String) ?? ERC20Balance(BigInt.zero);

    return EthereumWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      initialBalance: balance,
    );
  }

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchBalances();
    balance.addAll(await _client.fetchERC20Balances(_privateKey.address));
    await save();
  }

  Future<ERC20Balance> _fetchBalances() async {
    final balance = await _client.getBalance(_privateKey.address);
    return ERC20Balance(balance.getInWei);
  }

  Future<EthPrivateKey> getPrivateKey(String mnemonic, String password) async {
    final seed = bip39.mnemonicToSeed(mnemonic);

    final root = bip32.BIP32.fromSeed(seed);

    const _hdPathEthereum = "m/44'/60'/0'/0";
    const index = 0;
    final addressAtIndex = root.derivePath("$_hdPathEthereum/$index");

    return EthPrivateKey.fromHex(HEX.encode(addressAtIndex.privateKey as List<int>));
  }

  Future<void>? updateBalance() => null;

  List<CryptoCurrency> get erc20Currencies => _client.erc20Currencies.keys.toList();
}
