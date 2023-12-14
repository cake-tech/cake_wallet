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
import 'dummy_wallet_creation_credentials.dart';


class DummyWalletService extends WalletService<DummyNewWalletCredentials, DummyRestoreWalletFromSeedCredentials, DummyRestoreWalletFromKeyCredentials> {
  DummyWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> create(WalletCredentials credentials) => throw UnimplementedError();

  @override
  WalletType getType() => WalletType.dummy;

  @override
  Future<bool> isWalletExit(String name) => throw UnimplementedError();

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> openWallet(String name, String password) => throw UnimplementedError();

  @override
  Future<void> remove(String wallet) => throw UnimplementedError();

  @override
  Future<void> rename(String currentName, String password, String newName) => throw UnimplementedError();

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> restoreFromKeys(DummyRestoreWalletFromKeyCredentials credentials) => throw UnimplementedError();

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> restoreFromSeed(DummyRestoreWalletFromSeedCredentials credentials) => throw UnimplementedError();
}