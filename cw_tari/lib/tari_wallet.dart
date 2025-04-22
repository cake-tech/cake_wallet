import 'dart:async';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_tari/tari_balance.dart';
import 'package:cw_tari/tari_transaction_history.dart';
import 'package:cw_tari/tari_transaction_info.dart';
import 'package:cw_tari/tari_wallet_addresses.dart';
import 'package:cw_tari/transaction_credentials.dart';
import 'package:mobx/mobx.dart';
import 'package:tari/tari.dart' as tari;

part 'tari_wallet.g.dart';

class TariWallet = TariWalletBase with _$TariWallet;

abstract class TariWalletBase
    extends WalletBase<TariBalance, TariTransactionHistory, TariTransactionInfo>
    with Store, WalletKeysFile {
  TariWalletBase({
    required WalletInfo walletInfo,
    required String password,
    required tari.TariWallet walletFfi,
  })  : syncStatus = const NotConnectedSyncStatus(),
        walletAddresses = TariWalletAddresses(walletInfo),
        _password = password,
        _walletFfi = walletFfi,
        balance = ObservableMap<CryptoCurrency, TariBalance>.of({
          CryptoCurrency.tari:
              TariBalance.fromTariBalanceInfo(walletFfi.getBalance()),
        }),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = TariTransactionHistory();
  }

  final tari.TariWallet _walletFfi;
  final String _password;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, TariBalance> balance;

  Future<void> init() async {
    walletInfo.address = _walletFfi.getEmojiID().emojiId;

    await walletAddresses.init();
    await transactionHistory.init();

    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    return 0; // ToDo
  }

  @override
  Future<void> changePassword(String password) =>
      throw UnimplementedError("changePassword");

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    _walletFfi.close();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      // ToDo

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      _walletFfi.startRecovery((_, int status, int val1, int val2) {
        print('recoveryCallback called $status $val1 $val2');
      });

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final tariCredentials = credentials as TariTransactionCredentials;
    
    // _walletFfi.sendTx(destination, amount, feePerGram, message, isOneSided)
    // ToDo
    throw UnimplementedError();
  }

  @override
  Future<Map<String, TariTransactionInfo>> fetchTransactions() async {
    // ToDo
    throw UnimplementedError();
  }

  @override
  Object get keys => throw UnimplementedError("keys");

  @override
  Future<void> rescan({required int height}) {
    throw UnimplementedError("rescan");
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await transactionHistory.save();
  }

  @override
  String get seed => _walletFfi.getMnemonic();

  @override
  String? get privateKey => null;

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: seed,
        privateKey: privateKey,
        passphrase: passphrase,
      );

  @override
  Future<void> updateBalance() async {
    balance[CryptoCurrency.tari] =
        TariBalance.fromTariBalanceInfo(_walletFfi.getBalance());
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    // final transactionHistoryFileNameForWallet = getTransactionHistoryFileName();
    //
    // final currentWalletPath =
    //     await pathForWallet(name: walletInfo.name, type: type);
    // final currentWalletFile = File(currentWalletPath);
    //
    // final currentDirPath =
    //     await pathForWalletDir(name: walletInfo.name, type: type);
    // final currentTransactionsFile =
    //     File('$currentDirPath/$transactionHistoryFileNameForWallet');
    //
    // // Copies current wallet files into new wallet name's dir and files
    // if (currentWalletFile.existsSync()) {
    //   final newWalletPath =
    //       await pathForWallet(name: newWalletName, type: type);
    //   await currentWalletFile.copy(newWalletPath);
    // }
    // if (currentTransactionsFile.existsSync()) {
    //   final newDirPath =
    //       await pathForWalletDir(name: newWalletName, type: type);
    //   await currentTransactionsFile
    //       .copy('$newDirPath/$transactionHistoryFileNameForWallet');
    // }
    //
    // // Delete old name's dir and files
    // await Directory(currentDirPath).delete(recursive: true);
  }

  @override
  Future<String> signMessage(String message, {String? address}) async =>
      _walletFfi.signMessage(message);

  @override
  Future<bool> verifyMessage(String message, String signature,
      {String? address}) async {
    throw UnimplementedError();
  }

  @override
  String get password => _password;
}
