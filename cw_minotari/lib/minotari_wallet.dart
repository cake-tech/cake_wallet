import 'dart:async';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_minotari/minotari_balance.dart';
import 'package:cw_minotari/minotari_transaction_history.dart';
import 'package:cw_minotari/minotari_wallet_addresses.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:mobx/mobx.dart';

part 'minotari_wallet.g.dart';

class MinotariWallet = MinotariWalletBase with _$MinotariWallet;

abstract class MinotariWalletBase
    extends WalletBase<MinotariBalance, MinotariTransactionHistory, MinotariTransactionInfo>
    with Store {
  MinotariWalletBase(WalletInfo walletInfo)
      : balance = MinotariBalance(
          available: 0,
          pendingIncoming: 0,
          pendingOutgoing: 0,
        ),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = MinotariWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = MinotariTransactionHistory();
  }

  MinotariFfi? _ffi;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;

  @override
  MinotariWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  MinotariBalance balance;

  @override
  String? get seed => _ffi?.getMnemonic();

  @override
  String get password => '';

  @override
  WalletKeys get keys => WalletKeys(privateKey: '', publicKey: '');

  String get address => walletAddresses.address;

  @override
  Future<void> init() async {
    final path = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
    _ffi = MinotariFfi(dataPath: path);
    await updateBalance();
    await updateTransactions();
    _hasSyncAfterStartup = false;
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final nodeAddress = node.uriRaw;
      await _ffi?.sync(nodeAddress);

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      rethrow;
    }
  }

  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await updateBalance();
      await updateTransactions();
      syncStatus = SyncedSyncStatus();
      _hasSyncAfterStartup = true;
    } catch (e) {
      syncStatus = FailedSyncStatus();
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    // TODO: Implement transaction creation
    throw UnimplementedError('createTransaction not yet implemented');
  }

  @override
  Future<void> save() async {
    // Wallet state is saved automatically by the Rust layer
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    // TODO: Implement wallet file renaming
  }

  @override
  Future<void> changePassword(String password) async {
    // Minotari wallets don't use passwords in the traditional sense
    // The mnemonic is the key
  }

  @override
  Future<void> rescan({required int height}) async {
    await startSync();
  }

  @override
  Future<void> close({bool? silent = false}) async {
    _ffi?.dispose();
  }

  Future<void> updateBalance() async {
    try {
      final balanceData = await _ffi?.getBalance();
      if (balanceData != null) {
        balance = MinotariBalance(
          available: balanceData['available'] as int,
          pendingIncoming: balanceData['pendingIncoming'] as int,
          pendingOutgoing: balanceData['pendingOutgoing'] as int,
        );
      }
    } catch (e) {
      print('Error updating balance: $e');
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;

      // TODO: Fetch transactions from FFI layer
      // final transactions = await _ffi?.getTransactions();

      _isTransactionUpdating = false;
    } catch (e) {
      _isTransactionUpdating = false;
      print('Error updating transactions: $e');
    }
  }
}
