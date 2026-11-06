import 'package:cw_core/balance.dart';
import "package:cw_core/exceptions/cake_exception.dart";
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

class HavenWalletService extends WalletService {
  HavenWalletService();

  @override
  WalletType getType() => WalletType.haven;

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> create(
      WalletCredentials credentials,
      {bool? isTestnet}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isWalletExit(WalletInfo walletInfo) => throw UnsupportedWalletTypeException(getType());

  @override
  Future<WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>> openWallet(
      WalletInfo walletInfo, String password,) {
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
