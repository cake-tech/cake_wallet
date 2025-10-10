import 'dart:convert';

import 'package:cw_base/base_client.dart';
import 'package:cw_base/base_transaction_history.dart';
import 'package:cw_base/base_transaction_info.dart';
import 'package:cw_base/default_base_erc20_tokens.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_erc20_balance.dart';

class BaseWallet extends EVMChainWallet {
  BaseWallet({
    required super.walletInfo,
    required super.password,
    super.mnemonic,
    super.initialBalance,
    super.privateKey,
    required super.client,
    required super.encryptionFileUtils,
    super.passphrase,
  }) : super(nativeCurrency: CryptoCurrency.baseEth);

  @override
  Future<void> initErc20TokensBox() async {
    final boxName = "${walletInfo.name.replaceAll(" ", "_")}_ ${Erc20Token.baseBoxName}";

    evmChainErc20TokensBox = await CakeHive.openBox<Erc20Token>(boxName);
  }

  @override
  void addInitialTokens([bool isMigration = false]) {
    final initialErc20Tokens = DefaultBaseErc20Tokens().initialBaseErc20Tokens;

    for (final token in initialErc20Tokens) {
      if (evmChainErc20TokensBox.containsKey(token.contractAddress)) {
        final existingToken = evmChainErc20TokensBox.get(token.contractAddress);
        if (existingToken?.tag != token.tag) {
          evmChainErc20TokensBox.put(token.contractAddress, token);
        }
      } else {
        if (isMigration) token.enabled = false;
        evmChainErc20TokensBox.put(token.contractAddress, token);
      }
    }
  }

  @override
  List<String> get getDefaultTokenContractAddresses =>
      DefaultBaseErc20Tokens().initialBaseErc20Tokens.map((e) => e.contractAddress).toList();

  @override
  Future<bool> checkIfScanProviderIsEnabled() async {
   return (await sharedPrefs.future).getBool("use_basescan") ?? true;
  }

  @override
  String getTransactionHistoryFileName() => 'base_transactions.json';

  @override
  Erc20Token createNewErc20TokenObject(Erc20Token token, String? iconPath) {
    return Erc20Token(
      name: token.name,
      symbol: token.symbol,
      contractAddress: token.contractAddress,
      decimal: token.decimal,
      enabled: token.enabled,
      tag: token.tag ?? 'ETH',
      iconPath: iconPath,
      isPotentialScam: token.isPotentialScam,
    );
  }

  @override
  EVMChainTransactionInfo getTransactionInfo(
      EVMChainTransactionModel transactionModel, String address) {
    final model = BaseTransactionInfo(
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
      contractAddress: transactionModel.contractAddress,
    );
    return model;
  }

  @override
  EVMChainTransactionHistory setUpTransactionHistory(
      WalletInfo walletInfo, String password, EncryptionFileUtils encryptionFileUtils) {
    return BaseTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
    );
  }

  static Future<BaseWallet> open({
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

    return BaseWallet(
      walletInfo: walletInfo,
      password: password,
      mnemonic: keysData.mnemonic,
      privateKey: keysData.privateKey,
      passphrase: keysData.passphrase,
      initialBalance: balance,
      client: BaseClient(),
      encryptionFileUtils: encryptionFileUtils,
    );
  }
}
