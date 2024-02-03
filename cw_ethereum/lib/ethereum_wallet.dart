import 'dart:convert';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_ethereum/default_ethereum_erc20_tokens.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_erc20_balance.dart';
import 'package:cw_evm/file.dart';

class EthereumWallet extends EVMChainWallet {
  EthereumWallet({
    required super.client,
    required super.password,
    required super.walletInfo,
    super.mnemonic,
    super.initialBalance,
    super.privateKey,
  }) : super(nativeCurrency: CryptoCurrency.eth);

  @override
  void addInitialTokens() {
    final initialErc20Tokens = DefaultEthereumErc20Tokens().initialErc20Tokens;

    for (var token in initialErc20Tokens) {
      evmChainErc20TokensBox.put(token.contractAddress, token);
    }
  }

  @override
  Future<bool> checkIfScanProviderIsEnabled() async {
    bool isEtherscanEnabled = (await sharedPrefs.future).getBool("use_etherscan") ?? true;
    return isEtherscanEnabled;
  }

  @override
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
  EVMChainTransactionInfo getTransactionInfo(
      EVMChainTransactionModel transactionModel, String address) {
    final model = EthereumTransactionInfo(
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
      from: transactionModel.from,
    );
    return model;
  }

  @override
  String getTransactionHistoryFileName() => 'transactions.json';

  @override
  Erc20Token createNewErc20TokenObject(Erc20Token token, String? iconPath) {
    return Erc20Token(
      name: token.name,
      symbol: token.symbol,
      contractAddress: token.contractAddress,
      decimal: token.decimal,
      enabled: token.enabled,
      tag: token.tag ?? "ETH",
      iconPath: iconPath,
    );
  }

  @override
  EVMChainTransactionHistory setUpTransactionHistory(WalletInfo walletInfo, String password) {
    return EthereumTransactionHistory(walletInfo: walletInfo, password: password);
  }

  static Future<EthereumWallet> open(
      {required String name, required String password, required WalletInfo walletInfo}) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String?;
    final privateKey = data['private_key'] as String?;
    final balance = EVMChainERC20Balance.fromJSON(data['balance'] as String) ??
        EVMChainERC20Balance(BigInt.zero);

    return EthereumWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      privateKey: privateKey,
      initialBalance: balance,
      client: EthereumClient(),
    );
  }
}
