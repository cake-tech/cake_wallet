import 'dart:io';

import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_tari/callback.dart';
import 'package:cw_tari/tari_wallet.dart';
import 'package:hive/hive.dart';
import 'package:tari/tari.dart' as tari;

class TariNewWalletCredentials extends WalletCredentials {
  TariNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    super.passphrase,
  });
}

class TariRestoreWalletFromSeedCredentials extends WalletCredentials {
  TariRestoreWalletFromSeedCredentials({required super.name,
    required this.mnemonic,
    super.passphrase,
    super.height = 0,
    super.password});

  final String mnemonic;
}

class MoneroWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class TariRestoreWalletFromKeysCredentials extends WalletCredentials {
  TariRestoreWalletFromKeysCredentials({required String name,
    required String password,
    required this.language,
    required this.address,
    required this.viewKey,
    required this.spendKey,
    int height = 0})
      : super(name: name, password: password, height: height);

  final String language;
  final String address;
  final String viewKey;
  final String spendKey;
}

class TariWalletService extends WalletService<
    TariNewWalletCredentials,
    TariRestoreWalletFromSeedCredentials,
    TariRestoreWalletFromKeysCredentials,
    TariNewWalletCredentials> {
  TariWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static bool walletFilesExist(String path) => !File(path).existsSync();

  @override
  WalletType getType() => WalletType.tari;

  @override
  Future<TariWallet> create(TariNewWalletCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());

      final connection = tari.getTorConnection();
      final config = tari.getWalletConfig(
        path: path,
        transport: connection,
      );
      final tariWallet = tari.createWallet(
        commsConfig: config,
        passphrase: credentials.password!,
        logPath: "$path/logs/wallet.log",
        callbackReceivedTransaction: CallbackPlaceholders.callbackReceivedTransaction,
        callbackReceivedTransactionReply: CallbackPlaceholders.callbackReceivedTransactionReply,
        callbackReceivedFinalizedTransaction: CallbackPlaceholders.callbackReceivedFinalizedTransaction,
        callbackReceivedTransactionBroadcast: CallbackPlaceholders.callbackTransactionBroadcast,
        callbackReceivedTransactionMined: CallbackPlaceholders.callbackTransactionMined,
        callbackReceivedTransactionMinedUnconfirmed: CallbackPlaceholders.callbackTransactionMinedUnconfirmed,
        callbackFauxTransactionMinedConfirmed: CallbackPlaceholders.callbackFauxTransactionConfirmed,
        callbackFauxTransactionMinedUnconfirmed: CallbackPlaceholders.callbackFauxTransactionUnconfirmed,
        callbackTransactionSendResult: CallbackPlaceholders.callbackTransactionSendResult,
        callbackTransactionCancellation: CallbackPlaceholders.callbackTransactionCancellation,
        callbackTxoValidationComplete: CallbackPlaceholders.callbackTxoValidationComplete,
        callbackContactsLivenessDataUpdated: CallbackPlaceholders.callbackContactsLivenessDataUpdated,
        callbackBalanceUpdated: CallbackPlaceholders.callbackBalanceUpdated,
        callbackTransactionValidationComplete: CallbackPlaceholders.callbackTransactionValidationComplete,
        callbackSafMessagesReceived: CallbackPlaceholders.callbackSafMessagesReceived,
        callbackConnectivityStatus: CallbackPlaceholders.callbackConnectivityStatus,
        callbackWalletScannedHeight: CallbackPlaceholders.callbackWalletScannedHeight,
        callbackBaseNodeState: CallbackPlaceholders.callbackBaseNodeState,
      );

      final wallet = TariWallet(
        walletInfo: credentials.walletInfo!,
        password: credentials.password!,
        walletFfi: tariWallet,
      );
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).exists();

  @override
  Future<TariWallet> openWallet(String name, String password) async {
    try {
      final path = await pathForWallet(name: name, type: getType());
      final connection = tari.getTorConnection();
      final config = tari.getWalletConfig(
        path: path,
        transport: connection,
      );
      final tariWallet = tari.createWallet(
        commsConfig: config,
        passphrase: password,
        logPath: "$path/logs/wallet.log",
        callbackReceivedTransaction: CallbackPlaceholders.callbackReceivedTransaction,
        callbackReceivedTransactionReply: CallbackPlaceholders.callbackReceivedTransactionReply,
        callbackReceivedFinalizedTransaction: CallbackPlaceholders.callbackReceivedFinalizedTransaction,
        callbackReceivedTransactionBroadcast: CallbackPlaceholders.callbackTransactionBroadcast,
        callbackReceivedTransactionMined: CallbackPlaceholders.callbackTransactionMined,
        callbackReceivedTransactionMinedUnconfirmed: CallbackPlaceholders.callbackTransactionMinedUnconfirmed,
        callbackFauxTransactionMinedConfirmed: CallbackPlaceholders.callbackFauxTransactionConfirmed,
        callbackFauxTransactionMinedUnconfirmed: CallbackPlaceholders.callbackFauxTransactionUnconfirmed,
        callbackTransactionSendResult: CallbackPlaceholders.callbackTransactionSendResult,
        callbackTransactionCancellation: CallbackPlaceholders.callbackTransactionCancellation,
        callbackTxoValidationComplete: CallbackPlaceholders.callbackTxoValidationComplete,
        callbackContactsLivenessDataUpdated: CallbackPlaceholders.callbackContactsLivenessDataUpdated,
        callbackBalanceUpdated: CallbackPlaceholders.callbackBalanceUpdated,
        callbackTransactionValidationComplete: CallbackPlaceholders.callbackTransactionValidationComplete,
        callbackSafMessagesReceived: CallbackPlaceholders.callbackSafMessagesReceived,
        callbackConnectivityStatus: CallbackPlaceholders.callbackConnectivityStatus,
        callbackWalletScannedHeight: CallbackPlaceholders.callbackWalletScannedHeight,
        callbackBaseNodeState: CallbackPlaceholders.callbackBaseNodeState,
      );

      final walletInfo = walletInfoSource.values
          .firstWhere((info) => info.id == WalletBase.idFor(name, getType()));
      final wallet = TariWallet(
          walletInfo: walletInfo,
          password: password,
          walletFfi: tariWallet,
      );


      await wallet.init();

      return wallet;
    } catch (e) {
      printV(e);
      rethrow;
    }
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());

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
  Future<void> rename(String currentName, String password,
      String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhere(
            (info) => info.id == WalletBase.idFor(currentName, getType()));

    throw UnimplementedError();

    // await currentWallet.renameWalletFiles(newName);
    //
    // final newWalletInfo = currentWalletInfo;
    // newWalletInfo.id = WalletBase.idFor(newName, getType());
    // newWalletInfo.name = newName;
    //
    // await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<TariWallet> restoreFromKeys(
      TariRestoreWalletFromKeysCredentials credentials,
      {bool? isTestnet}) async {
    throw UnimplementedError();
  }

  @override
  Future<TariWallet> restoreFromHardwareWallet(
      TariNewWalletCredentials credentials) async {
    throw UnimplementedError();
  }

  @override
  Future<TariWallet> restoreFromSeed(
      TariRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    try {
      final path = await pathForWallet(name: credentials.name, type: getType());

      final connection = tari.getTorConnection();
      final config = tari.getWalletConfig(
        path: path,
        transport: connection,
      );
      final tariWallet = tari.createWallet(
        commsConfig: config,
        passphrase: credentials.password!,
        mnemonic: credentials.mnemonic,
        seedPassphrase: credentials.passphrase ?? "",
        logPath: "$path/logs/wallet.log",
        callbackReceivedTransaction: CallbackPlaceholders.callbackReceivedTransaction,
        callbackReceivedTransactionReply: CallbackPlaceholders.callbackReceivedTransactionReply,
        callbackReceivedFinalizedTransaction: CallbackPlaceholders.callbackReceivedFinalizedTransaction,
        callbackReceivedTransactionBroadcast: CallbackPlaceholders.callbackTransactionBroadcast,
        callbackReceivedTransactionMined: CallbackPlaceholders.callbackTransactionMined,
        callbackReceivedTransactionMinedUnconfirmed: CallbackPlaceholders.callbackTransactionMinedUnconfirmed,
        callbackFauxTransactionMinedConfirmed: CallbackPlaceholders.callbackFauxTransactionConfirmed,
        callbackFauxTransactionMinedUnconfirmed: CallbackPlaceholders.callbackFauxTransactionUnconfirmed,
        callbackTransactionSendResult: CallbackPlaceholders.callbackTransactionSendResult,
        callbackTransactionCancellation: CallbackPlaceholders.callbackTransactionCancellation,
        callbackTxoValidationComplete: CallbackPlaceholders.callbackTxoValidationComplete,
        callbackContactsLivenessDataUpdated: CallbackPlaceholders.callbackContactsLivenessDataUpdated,
        callbackBalanceUpdated: CallbackPlaceholders.callbackBalanceUpdated,
        callbackTransactionValidationComplete: CallbackPlaceholders.callbackTransactionValidationComplete,
        callbackSafMessagesReceived: CallbackPlaceholders.callbackSafMessagesReceived,
        callbackConnectivityStatus: CallbackPlaceholders.callbackConnectivityStatus,
        callbackWalletScannedHeight: CallbackPlaceholders.callbackWalletScannedHeight,
        callbackBaseNodeState: CallbackPlaceholders.callbackBaseNodeState,
      );
      final wallet = TariWallet(
          walletInfo: credentials.walletInfo!,
          walletFfi: tariWallet,
          password: credentials.password!);
      await wallet.init();

      return wallet;
    } catch (e) {
      // TODO: Implement Exception for wallet list service.
      printV('MoneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  bool requireHardwareWalletConnection(String name) {
    return false;
  }
}
