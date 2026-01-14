import 'dart:async';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_minotari/minotari_balance.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:cw_minotari/minotari_transaction_history.dart';
import 'package:cw_minotari/minotari_transaction_info.dart';
import 'package:cw_minotari/minotari_wallet_addresses.dart';
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:mobx/mobx.dart';

part 'minotari_wallet.g.dart';

class MinotariWallet = MinotariWalletBase with _$MinotariWallet;

abstract class MinotariWalletBase
    extends WalletBase<MinotariBalance, MinotariTransactionHistory, MinotariTransactionInfo>
    with Store {
  MinotariWalletBase(WalletInfo walletInfo, DerivationInfo derivationInfo)
      : balance = ObservableMap.of({
          CryptoCurrency.xtm: MinotariBalance(
            available: 0,
            pendingIncoming: 0,
            pendingOutgoing: 0,
          )
        }),
        _isTransactionUpdating = false,
        walletAddresses = MinotariWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo, derivationInfo) {
    transactionHistory = MinotariTransactionHistory();
  }

  MinotariFfi? _ffi;
  bool _isTransactionUpdating;
  StreamSubscription<ScanEventDto>? _scannerSubscription;
  Node? _currentNode;

  @override
  MinotariWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MinotariBalance> balance;

  @override
  String? get seed => _ffi?.getMnemonic();

  @override
  String get password => '';

  @override
  Object get keys => {};

  String get address => walletAddresses.address;

  Future<void> init() async {
    try {
      final path = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
      _ffi = MinotariFfi(dataPath: path);

      // Get the network from wallet info (defaults to mainnet if not set)
     final network = TariNetwork.values.firstWhere(
       (n) => n.name == walletInfo.network,
       orElse: () => TariNetwork.mainNet,
     );

      // Open the existing wallet database with the correct network
      await _ffi?.open(network);

      // Get the wallet address from the Rust layer (it's persisted there)
      final address = await _ffi?.getAddress();
      if (address != null && address.isNotEmpty) {
        walletAddresses.setAddress(address);
      } else {
        printV('Warning: Could not retrieve wallet address from FFI');
      }

      await updateBalance();
      await updateTransactions();
    } catch (e) {
      printV('Error initializing Minotari wallet: $e');
      rethrow;
    }
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      // Store the node for later use
      _currentNode = node;

      // Test connection by fetching balance
      await updateBalance();

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

      // Cancel any existing scanner subscription
      await _scannerSubscription?.cancel();

      // Get the node URL (with protocol) from current node
      if (_currentNode == null) {
        throw Exception('No node connected. Call connectToNode first.');
      }

      final nodeUrl = _currentNode!.uri.toString();

      // Start the scanner stream
      final scanStream = _ffi?.startScan(
        baseNodeAddress: nodeUrl,
        continuous: false, // One-time sync
      );

      if (scanStream == null) {
        throw Exception('Scanner not initialized');
      }

      // Listen to scan events
      _scannerSubscription = scanStream.listen(
        (event) {
          _handleScanEvent(event);
        },
        onError: (error) {
          printV('Scanner error: $error');
          syncStatus = FailedSyncStatus();
        },
        onDone: () async {
          // Scan completed, update balance and transactions
          await updateBalance();
          await updateTransactions();
          syncStatus = SyncedSyncStatus();
        },
      );

      syncStatus = SyncronizingSyncStatus();
    } catch (e) {
      printV('Error starting sync: $e');
      syncStatus = FailedSyncStatus();
      rethrow;
    }
  }

  /// Handle scan events from the scanner stream
  void _handleScanEvent(ScanEventDto event) {
    event.when(
      status: (status) {
        status.when(
          started: (accountId, fromHeight) {
            printV('Scan started from height: $fromHeight');
            syncStatus = SyncronizingSyncStatus();
          },
          progress: (accountId, currentHeight, blocksScanned) {
            printV('Scan progress: height $currentHeight, scanned $blocksScanned blocks');
            // TODO We don't know the chain tip height, so we can't calculate
            // meaningful progress
            // Just show "Synchronizing" status without percentage
            syncStatus = SyncronizingSyncStatus();
          },
          completed: (accountId, finalHeight, totalBlocksScanned) {
            printV('Scan completed at height $finalHeight, total blocks: $totalBlocksScanned');
          },
          paused: (accountId, lastScannedHeight, reason) {
            printV('Scan paused at height $lastScannedHeight: $reason');
          },
          waiting: (accountId, resumeInSeconds) {
            printV('Scanner waiting, resume in $resumeInSeconds seconds');
          },
          moreBlocksAvailable: (accountId, lastScannedHeight) {
            printV('More blocks available after height $lastScannedHeight');
          },
        );
      },
      transactionsReady: (dto) async {
        printV('Transactions ready: ${dto.transactions.length} transactions');
        // Update transactions immediately when discovered
        await _processNewTransactions(dto.transactions);
      },
      transactionsUpdated: (dto) async {
        printV('Transactions updated: ${dto.updatedTransactions.length} transactions');
        // Update existing transactions
        await _processNewTransactions(dto.updatedTransactions);
      },
      error: (errorMessage) {
        printV('Scanner error: $errorMessage');
        syncStatus = FailedSyncStatus();
      },
    );
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
  Future<void> close({bool shouldCleanup = false}) async {
    await _scannerSubscription?.cancel();
    _scannerSubscription = null;
    await _ffi?.stopScan();
    _ffi?.dispose();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // Stub implementation - return 0 fee for now
    return 0;
  }

  @override
  Future<bool> checkNodeHealth() async {
    // Stub implementation - always return true
    return true;
  }

  @override
  Future<Map<String, MinotariTransactionInfo>> fetchTransactions() async {
    // Stub implementation - return empty map
    return {};
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    // Stub implementation
    throw UnimplementedError('signMessage not yet implemented');
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    // Stub implementation
    return false;
  }

  Future<void> updateBalance() async {
    try {
      final balanceData = await _ffi?.getBalance();
      if (balanceData != null) {
        balance[CryptoCurrency.xtm] = MinotariBalance(
          available: balanceData['available'] as int,
          pendingIncoming: balanceData['pendingIncoming'] as int,
          pendingOutgoing: balanceData['pendingOutgoing'] as int,
        );
      }
    } catch (e) {
      printV('Error updating balance: $e');
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;

      // Fetch transactions from FFI layer
      final txDtos = await _ffi?.getTransactions();
      if (txDtos != null && txDtos.isNotEmpty) {
        await _processNewTransactions(txDtos);
      }

      _isTransactionUpdating = false;
    } catch (e) {
      _isTransactionUpdating = false;
      printV('Error updating transactions: $e');
    }
  }

  /// Process new transactions from the FFI layer
  Future<void> _processNewTransactions(List<dynamic> transactions) async {
    for (final txDynamic in transactions) {
      try {
        // Cast to proper type
        final txDto = txDynamic as DisplayedTransactionDto;

        final directionStr = txDto.direction.toLowerCase();
        final direction = directionStr == 'inbound' || directionStr == 'incoming'
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing;

        final statusStr = txDto.status.toLowerCase();
        // TODO use constants or enum!!
        final isPending = statusStr != 'completed' && statusStr != 'confirmed';
        final date = DateTime.tryParse(txDto.blockchain.timestamp) ?? DateTime.now();
        final fee = txDto.fee?.amount.toInt();

        final txInfo = MinotariTransactionInfo(
          id: txDto.id,
          amount: txDto.amount.toInt(),
          date: date,
          direction: direction,
          isPending: isPending,
          fee: fee,
          height: txDto.blockchain.blockHeight.toInt(),
          confirmations: txDto.blockchain.confirmations.toInt(),
        );

        transactionHistory.transactions[txDto.id] = txInfo;
      } catch (e) {
        printV('Error processing transaction: $e');
      }
    }

    await transactionHistory.save();
  }
}
