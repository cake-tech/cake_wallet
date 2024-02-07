import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:cw_evm/evm_chain_wallet_service.dart';
import 'package:cw_tron/tron_client.dart';
import 'package:cw_tron/tron_mnemonics_exception.dart';
import 'package:cw_tron/tron_wallet.dart';

class TronWalletService extends EVMChainWalletService<TronWallet> {
  TronWalletService(
    super.walletInfoSource, {
    required this.client,
  });

  late TronClient client;

  @override
  WalletType getType() => WalletType.tron;

  @override
  Future<TronWallet> create(EVMChainNewWalletCredentials credentials) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = bip39.generateMnemonic(strength: strength);

    final wallet = TronWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
      client: client,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<TronWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
    final wallet = await TronWallet.open(
      name: name,
      password: password,
      walletInfo: walletInfo,
    );

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<TronWallet> restoreFromKeys(EVMChainRestoreWalletFromPrivateKey credentials) async {

    final wallet = TronWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      client: client,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<TronWallet> restoreFromSeed(
      EVMChainRestoreWalletFromSeedCredentials credentials) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw TronMnemonicIsIncorrectException();
    }

    final wallet = TronWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      client: client,
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = await TronWallet.open(
        password: password, name: currentName, walletInfo: currentWalletInfo);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }
}
