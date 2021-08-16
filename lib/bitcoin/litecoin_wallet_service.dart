import 'dart:io';
import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic.dart';
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic_is_incorrect_exception.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cake_wallet/bitcoin/litecoin_wallet.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/pathForWallet.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/core/wallet_base.dart';

class LitecoinWalletService extends WalletService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials> {
  LitecoinWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;

  @override
  WalletType getType() => WalletType.litecoin;

  @override
  Future<LitecoinWallet> create(BitcoinNewWalletCredentials credentials) async {
    final wallet = LitecoinWallet(
        mnemonic: await generateMnemonic(),
        password: credentials.password,
        walletInfo: credentials.walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.save();
    await wallet.init();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<LitecoinWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values.firstWhere(
        (info) => info.id == WalletBase.idFor(name, getType()),
        orElse: () => null);
    final wallet = await LitecoinWalletBase.open(
        password: password, name: name, walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async =>
      File(await pathForWalletDir(name: wallet, type: getType()))
          .delete(recursive: true);

  @override
  Future<LitecoinWallet> restoreFromKeys(
          BitcoinRestoreWalletFromWIFCredentials credentials) async =>
      throw UnimplementedError();

  @override
  Future<LitecoinWallet> restoreFromSeed(
      BitcoinRestoreWalletFromSeedCredentials credentials) async {
    if (!validateMnemonic(credentials.mnemonic)) {
      throw BitcoinMnemonicIsIncorrectException();
    }

    final wallet = LitecoinWallet(
        password: credentials.password,
        mnemonic: credentials.mnemonic,
        walletInfo: credentials.walletInfo,
        unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.save();
    await wallet.init();
    return wallet;
  }
}
