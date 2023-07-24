import 'dart:io';

import 'package:cw_bitcoin_cash/cw_bitcoin_cash.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

import 'bitcoin_cash_wallet_creation_credentials.dart';

class BitcoinCashWalletService extends WalletService<BitcoinCashNewWalletCredentials,
    BitcoinCashRestoreWalletFromSeedCredentials, BitcoinCashRestoreWalletFromWIFCredentials> {
  BitcoinCashWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;



  @override
  WalletType getType() => WalletType.bitcoinCash;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> create(credentials) async {
    final wallet = await BitcoinCashWalletBase.create(
        mnemonic: await Mnemonic.generate(),
    password: credentials.password!,
    walletInfo: credentials.walletInfo!,
    unspentCoinsInfo: unspentCoinsInfoSource);
    await wallet.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> openWallet(String name, String password) {
    // TODO: implement openWallet
    throw UnimplementedError();
  }

  @override
  Future<void> remove(String wallet) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> rename(String currentName, String password, String newName) {
    // TODO: implement rename
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> restoreFromKeys(credentials) {
    // TODO: implement restoreFromKeys
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> restoreFromSeed(credentials) {
    // TODO: implement restoreFromSeed
    throw UnimplementedError();
  }

}