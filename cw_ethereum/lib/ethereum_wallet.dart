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
import 'package:cw_core/erc20_token.dart';
import 'package:hive/hive.dart';
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

    if (!Hive.isAdapterRegistered(Erc20Token.typeId)) {
      Hive.registerAdapter(Erc20TokenAdapter());
    }
  }

  final String _mnemonic;
  final String _password;

  late final Box<Erc20Token> erc20TokensBox;

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
    erc20TokensBox = await Hive.openBox<Erc20Token>(Erc20Token.boxName);
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
  void close() {
    _client.stop();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final isConnected = _client.connect(node);

      if (!isConnected) {
        throw Exception("Ethereum Node connection failed");
      }

      _client.setListeners(_privateKey.address, _onNewTransaction);
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
    } catch (e) {
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
    balance[currency] = await _fetchEthBalance();

    await _fetchErc20Balances();
    await save();
  }

  Future<ERC20Balance> _fetchEthBalance() async {
    final balance = await _client.getBalance(_privateKey.address);
    return ERC20Balance(balance.getInWei);
  }

  Future<void> _fetchErc20Balances() async {
    for (var token in erc20TokensBox.values) {
      try {
        if (token.enabled) {
          balance[token] = await _client.fetchERC20Balances(
            _privateKey.address,
            token.contractAddress,
          );
        } else {
          balance.remove(token);
        }
      } catch (_) {}
    }
  }

  Future<EthPrivateKey> getPrivateKey(String mnemonic, String password) async {
    final seed = bip39.mnemonicToSeed(mnemonic);

    final root = bip32.BIP32.fromSeed(seed);

    const _hdPathEthereum = "m/44'/60'/0'/0";
    const index = 0;
    final addressAtIndex = root.derivePath("$_hdPathEthereum/$index");

    return EthPrivateKey.fromHex(HEX.encode(addressAtIndex.privateKey as List<int>));
  }

  Future<void>? updateBalance() async => await _updateBalance();

  List<Erc20Token> get erc20Currencies => erc20TokensBox.values.toList();

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
      iconPath: iconPath,
    );

    await erc20TokensBox.put(_token.contractAddress, _token);

    if (_token.enabled) {
      balance[_token] = await _client.fetchERC20Balances(
        _privateKey.address,
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

  void _onNewTransaction(FilterEvent event) {
    _updateBalance();
    // TODO: Add in transaction history
  }

  void addInitialTokens() {
    final Map<CryptoCurrency, Map<String, dynamic>> _initialErc20Currencies = {
      CryptoCurrency.usdc: {
        'contractAddress': "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        'decimal': 6,
        'enabled': true,
      },
      CryptoCurrency.usdterc20: {
        'contractAddress': "0xdac17f958d2ee523a2206206994597c13d831ec7",
        'decimal': 6,
        'enabled': true,
      },
      CryptoCurrency.dai: {
        'contractAddress': "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        'decimal': 18,
        'enabled': true,
      },
      CryptoCurrency.weth: {
        'contractAddress': "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.pepe: {
        'contractAddress': "0x6982508145454ce325ddbe47a25d4ec3d2311933",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.shib: {
        'contractAddress': "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.ape: {
        'contractAddress': "0x4d224452801aced8b2f0aebe155379bb5d594381",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.matic: {
        'contractAddress': "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.wbtc: {
        'contractAddress': "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        'decimal': 8,
        'enabled': false,
      },
      CryptoCurrency.gtc: {
        'contractAddress': "0xde30da39c46104798bb5aa3fe8b9e0e1f348163f",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.comp: {
        'contractAddress': "0xc00e94cb662c3520282e6f5717214004a7f26888",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.aave: {
        'contractAddress': "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.uni: {
        'contractAddress': "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.mana: {
        'contractAddress': "0x0f5d2fb29fb7d3cfee444a200298f468908cc942",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.storj: {
        'contractAddress': "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac",
        'decimal': 8,
        'enabled': false,
      },
      CryptoCurrency.mkr: {
        'contractAddress': "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.oxt: {
        'contractAddress': "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.paxg: {
        'contractAddress': "0x45804880De22913dAFE09f4980848ECE6EcbAf78",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.bnb: {
        'contractAddress': "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
        'decimal': 18,
        'enabled': true,
      },
      CryptoCurrency.steth: {
        'contractAddress': "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.ldo: {
        'contractAddress': "0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.arb: {
        'contractAddress': "0xB50721BCf8d664c30412Cfbc6cf7a15145234ad1",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.grt: {
        'contractAddress': "0xc944E90C64B2c07662A292be6244BDf05Cda44a7",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.frax: {
        'contractAddress': "0x853d955aCEf822Db058eb8505911ED77F175b99e",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.gusd: {
        'contractAddress': "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.ceth: {
        'contractAddress': "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5",
        'decimal': 8,
        'enabled': false,
      },
      CryptoCurrency.busd: {
        'contractAddress': "0x4Fabb145d64652a948d72533023f6E7A623C7C53",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.tusd: {
        'contractAddress': "0x0000000000085d4780B73119b644AE5ecd22b376",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.cro: {
        'contractAddress': "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b",
        'decimal': 8,
        'enabled': false,
      },
      CryptoCurrency.usdp: {
        'contractAddress': "0x8E870D67F660D95d5be530380D0eC0bd388289E1",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.ftm: {
        'contractAddress': "0x4E15361FD6b4BB609Fa63C81A2be19d873717870",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.btt: {
        'contractAddress': "0xC669928185DbCE49d2230CC9B0979BE6DC797957",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.nexo: {
        'contractAddress': "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.dydx: {
        'contractAddress': "0x92D6C1e31e14520e676a687F0a93788B716BEff5",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.cake: {
        'contractAddress': "0x152649eA73beAb28c5b49B26eb48f7EAD6d4c898",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.bat: {
        'contractAddress': "0x0D8775F648430679A709E98d2b0Cb6250d2887EF",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.1inch: {
        'contractAddress': "0x111111111117dC0aa78b770fA6A738034120C302",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.ens: {
        'contractAddress': "0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72",
        'decimal': 18,
        'enabled': false,
      },
      CryptoCurrency.zrx: {
        'contractAddress': "0xE41d2489571d322189246DaFA5ebDe1F4699F498",
        'decimal': 18,
        'enabled': false,
      },
    };

    for (var currency in _initialErc20Currencies.keys) {
      erc20TokensBox.put(
          _initialErc20Currencies[currency]!['contractAddress'],
          Erc20Token(
            name: currency.fullName ?? currency.title,
            symbol: currency.title,
            contractAddress: _initialErc20Currencies[currency]!['contractAddress'],
            decimal: _initialErc20Currencies[currency]!['decimal'],
            enabled: _initialErc20Currencies[currency]!['enabled'] ?? true,
            iconPath: currency.iconPath,
          ));
    }
  }
}
