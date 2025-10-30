import 'dart:convert';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_ethereum/default_ethereum_erc20_tokens.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_erc20_balance.dart';
import 'package:web3dart/web3dart.dart';

class EthereumWallet extends EVMChainWallet {
  EthereumWallet({
    required super.client,
    required super.password,
    required super.walletInfo,
    super.mnemonic,
    super.initialBalance,
    super.privateKey,
    required super.encryptionFileUtils,
    super.passphrase,
  }) : super(nativeCurrency: CryptoCurrency.eth);

  @override
  int getTotalPriorityFee(EVMChainTransactionPriority priority) {
    return EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();
  }

  @override
  void addInitialTokens() {
    final initialErc20Tokens = DefaultEthereumErc20Tokens().initialErc20Tokens;

    for (final token in initialErc20Tokens) {
      if (!evmChainErc20TokensBox.containsKey(token.contractAddress)) {
        evmChainErc20TokensBox.put(token.contractAddress, token);
      } else {
        // update existing token
        final existingToken = evmChainErc20TokensBox.get(token.contractAddress);
        evmChainErc20TokensBox.put(
            token.contractAddress, Erc20Token.copyWith(token, enabled: existingToken!.enabled));
      }
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
    await evmChainErc20TokensBox.addAll(allValues);
  }

  @override
  List<String> get getDefaultTokenContractAddresses =>
      DefaultEthereumErc20Tokens().initialErc20Tokens.map((e) => e.contractAddress).toList();

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
      evmSignatureName: transactionModel.evmSignatureName,
      contractAddress: transactionModel.contractAddress,
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
      isPotentialScam: token.isPotentialScam,
    );
  }

  @override
  EVMChainTransactionHistory setUpTransactionHistory(
      WalletInfo walletInfo, String password, EncryptionFileUtils encryptionFileUtils) {
    return EthereumTransactionHistory(
        walletInfo: walletInfo, password: password, encryptionFileUtils: encryptionFileUtils);
  }

  static Future<EthereumWallet> open({
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

    final balance = EVMChainERC20Balance.fromJSON(data?['balance'] as String?) ??
        EVMChainERC20Balance(BigInt.zero);

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

    return EthereumWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: keysData.mnemonic,
      privateKey: keysData.privateKey,
      passphrase: keysData.passphrase,
      initialBalance: balance,
      client: EthereumClient(),
      encryptionFileUtils: encryptionFileUtils,
    );
  }
}
