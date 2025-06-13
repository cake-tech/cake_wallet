import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_tari/callback.dart';
import 'package:cw_tari/pending_tari_transaction.dart';
import 'package:cw_tari/tari_balance.dart';
import 'package:cw_tari/tari_transaction_history.dart';
import 'package:cw_tari/tari_transaction_info.dart';
import 'package:cw_tari/tari_wallet_addresses.dart';
import 'package:cw_tari/transaction_credentials.dart';
import 'package:mobx/mobx.dart';
import 'package:tari/ffi.dart';
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
    final address = _walletFfi.getEmojiID();
    walletInfo.address = address.base58;

    await walletAddresses.init();
    await transactionHistory.init();

    (walletAddresses as TariWalletAddresses).emojiAddress = address.emojiId;

    await save();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) =>
      _walletFfi.estimateFee(amount ?? 1_000_000, null);

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
    syncStatus = ConnectingSyncStatus();
    syncStatus = ConnectedSyncStatus();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      _walletFfi.setBaseNode();

      await Future.delayed(Duration(seconds: 10)); // Give it time to connect to the base node

      var isRecovering = true;
      _walletFfi.startRecovery((_, event, arg1, arg2) {
        switch (event) {
          case 0:
            print("[Recovery] Connecting to base node...");
            break;
          case 1:
            print("[Recovery] Connection to base node established");
            break;
          case 2:
            print("[Recovery] Connection to base node failed. Retry ${arg1}/${arg2}");
            break;
          case 3:
            print("[Recovery] Scanning progress: ${arg1}/${arg2} blocks");
            isRecovering = false;
            break;
          case 4:
            print(
                "[Recovery] Recovery completed! Recovered ${arg1} UTXOs (${arg2} MicroMinotari)");
            isRecovering = false;
            break;
          case 5:
            print("[Recovery] Scanning round failed. Retry ${arg1}/${arg2}");
            break;
          case 6:
            print("[Recovery] Recovery failed!");
            isRecovering = false;
            break;
          default:
            print("[Recovery] Unknown event: $event ${arg1} ${arg2}");
            break;
        }
      });
      await Future.delayed(Duration(seconds: 15)); // Give it time to scan the blocks

      while (isRecovering) {
        await Future.delayed(Duration(seconds: 5)); // Check every 5 seconds
        final balance = _walletFfi.getBalance();
        print("Scanned height: ${CallbackPlaceholders.scannedHeight} / ${CallbackPlaceholders.chainTipHeight}");
        print(
            "Balance: ${balance.available} ${balance.pendingIncoming} ${balance.pendingOutgoing} ${balance.timeLocked}");
        if (CallbackPlaceholders.scannedHeight >= CallbackPlaceholders.chainTipHeight && CallbackPlaceholders.chainTipHeight > 0) {
          break;
        }
      }

      // syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final tariCredentials = credentials as TariTransactionCredentials;
    final fee = BigInt.from(tariCredentials.feeRate ?? 10);
    BigInt amount = BigInt.zero;

    Function sendTransaction = () {};
    for (final output in tariCredentials.outputs) {
      FFITariWalletAddress destination;
      if (output.address.startsWith("🌈")) { // ToDo change to Mainnet
        destination = FFITariWalletAddress.fromEmojiId(output.address);
      } else {
        destination = FFITariWalletAddress.fromBase58(output.address);
      }
      amount = BigInt.parse(output.cryptoAmount ?? '0');
      sendTransaction = () => _walletFfi.sendTx(
            destination,
            amount,
            fee,
            output.note ?? "",
            true,
          );
    }

    return PendingTariTransaction(
      sendTransaction: sendTransaction,
      fee: fee,
      amount: amount,
      exponent: 6,
    );
  }

  @override
  Future<Map<String, TariTransactionInfo>> fetchTransactions() async {
    final transactions = _walletFfi.getCompletedTxs();
    final Map<String, TariTransactionInfo> result = {};

    for (final tx in transactions) {
      result[tx.getId()] = TariTransactionInfo(
        tx.getId(),
        0,
        tx.isOutbound()
            ? TransactionDirection.outgoing
            : TransactionDirection.incoming,
        DateTime.fromMillisecondsSinceEpoch(tx.getTimestamp().toInt()),
        false,
        tx.getAmount().toInt(),
        0,
        0,
        tx.getFee().toInt(),
        tx.getConfirmationCount().toInt(),
      );
    }

    return result;
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

  Future<void> dev_printLogs() async {
    final currentWalletPath =
        await pathForWallet(name: walletInfo.name, type: type);
    final files = Directory("$currentWalletPath/logs").listSync();
    files.forEach((e) => log(e.path));
    File(files.last.path).readAsString().then((e) => log(e));
  }

  @override
  String get password => _password;
}
