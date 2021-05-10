import 'dart:io';
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic.dart';
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic_is_incorrect_exception.dart';
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/entities/pathForWallet.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:hive/hive.dart';

class BitcoinWalletService extends WalletService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials> {
  BitcoinWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<BitcoinWallet> create(BitcoinNewWalletCredentials credentials) async {
    final dirPath = await pathForWalletDir(
        type: WalletType.bitcoin, name: credentials.name);
    final wallet = BitcoinWalletBase.build(
        dirPath: dirPath,
        mnemonic: await generateMnemonic(),
        password: credentials.password,
        name: credentials.name,
        walletInfo: credentials.walletInfo);
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: WalletType.bitcoin))
          .existsSync();

  @override
  Future<BitcoinWallet> openWallet(String name, String password) async {
    final walletDirPath =
        await pathForWalletDir(name: name, type: WalletType.bitcoin);
    final walletPath = '$walletDirPath/$name';
    final walletJSONRaw = await read(path: walletPath, password: password);
    final walletInfo = walletInfoSource.values.firstWhere(
        (info) => info.id == WalletBase.idFor(name, WalletType.bitcoin),
        orElse: () => null);
    final wallet = BitcoinWalletBase.fromJSON(
        password: password,
        name: name,
        dirPath: walletDirPath,
        jsonSource: walletJSONRaw,
        walletInfo: walletInfo);
    await wallet.init();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async =>
      File(await pathForWalletDir(name: wallet, type: WalletType.bitcoin))
          .delete(recursive: true);

  @override
  Future<BitcoinWallet> restoreFromKeys(
      BitcoinRestoreWalletFromWIFCredentials credentials) async {
    // TODO: implement restoreFromKeys
    throw UnimplementedError();
  }

  @override
  Future<BitcoinWallet> restoreFromSeed(
      BitcoinRestoreWalletFromSeedCredentials credentials) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw BitcoinMnemonicIsIncorrectException();
    }

    final dirPath = await pathForWalletDir(
        type: WalletType.bitcoin, name: credentials.name);
    final wallet = BitcoinWalletBase.build(
        dirPath: dirPath,
        name: credentials.name,
        password: credentials.password,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo);
    await wallet.save();
    await wallet.init();

    return wallet;
  }
}
