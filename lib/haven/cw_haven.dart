import 'dart:io';

import 'package:cw_core/balance.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

class HavenWalletService extends WalletService {
  final Box<WalletInfo> walletInfoSource;

  HavenWalletService(this.walletInfoSource);

  @override
  WalletType getType() => WalletType.haven;

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: WalletType.haven);

    final file = Directory(path);
    final isExist = file.existsSync();

    if (isExist) {
      await file.delete(recursive: true);
    }

    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(wallet, getType()));
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> create(
      WalletCredentials credentials,
      {bool? isTestnet}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isWalletExit(String name) {
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> openWallet(
      String name, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> rename(String currentName, String password, String newName) {
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      restoreFromHardwareWallet(WalletCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      restoreFromKeys(WalletCredentials credentials, {bool? isTestnet}) {
    throw UnimplementedError();
  }

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>>
      restoreFromSeed(WalletCredentials credentials, {bool? isTestnet}) {
    throw UnimplementedError();
  }
}
