import 'dart:async';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_minotari/minotari_balance.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:cw_minotari/minotari_transaction_history.dart';
import 'package:cw_minotari/minotari_transaction_info.dart';
import 'package:cw_minotari/minotari_wallet_addresses.dart';
import 'package:cw_minotari/pending_minotari_transaction.dart';
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:mobx/mobx.dart';

part 'minotari_wallet.g.dart';

class MinotariWallet = MinotariWalletBase with _$MinotariWallet;

abstract class MinotariWalletBase
    extends WalletBase<MinotariBalance, MinotariTransactionHistory, MinotariTransactionInfo>
    with Store, WalletKeysFile {
  MinotariWalletBase(
    WalletInfo walletInfo,
    DerivationInfo derivationInfo, {
    String? mnemonic,
    required String password,
    required this.encryptionFileUtils,
    this.passphrase,
  })  : _mnemonic = mnemonic,
        _password = password,
        balance = ObservableMap.of({
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

  final String _password;
  final String? _mnemonic;
  final EncryptionFileUtils encryptionFileUtils;

  @override
  MinotariWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MinotariBalance> balance;

  @override
  String? get seed => _mnemonic;

  /// password - for encrypting/decrypting the .keys file
  @override
  String get password => _password;

  /// BIP39 passphrase used for seed derivation
  @override
  final String? passphrase;

  @override
  WalletKeysData get walletKeysData => WalletKeysData(mnemonic: _mnemonic, passphrase: passphrase);

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
      final address = await _ffi?.getAddress(passphrase: passphrase ?? '');
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

  /// TODO Sometimes receives an error "AnyhowException(Intermittent error:
  /// Scanning error: Blockchain connection failed: Failed to get header at
  /// height 186479)"
  /// Need to investigate further
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
        passphrase: passphrase ?? '',
        continuous: false, // One-time sync
      );

      if (scanStream == null) {
        throw Exception('Scanner not initialized');
      }

      // Listen to scan events
      _scannerSubscription = scanStream.listen(
        (event) {
          try {
            _handleScanEvent(event);
          } catch (e) {
            printV('Error handling scan event: $e');
            syncStatus = FailedSyncStatus();
          }
        },
        onError: (error) {
          printV('Scanner stream error: $error');
          syncStatus = FailedSyncStatus();
        },
        onDone: () async {
          // Scan completed, update balance and transactions
          try {
            await updateBalance();
            await updateTransactions();
            syncStatus = SyncedSyncStatus();
          } catch (e) {
            printV('Error updating after scan: $e');
            syncStatus = FailedSyncStatus();
          }
        },
        cancelOnError: true, // Stop listening after an error
      );

      syncStatus = SyncronizingSyncStatus();
    } catch (e) {
      printV('Error starting sync: $e');
      syncStatus = FailedSyncStatus();
      // Don't rethrow - we've already set FailedSyncStatus
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
      transactionsReady: (dto) {
        printV('Transactions ready: ${dto.transactions.length} transactions');
        // Update transactions immediately when discovered (fire-and-forget)
        _processNewTransactions(dto.transactions).catchError((e) {
          printV('Error processing new transactions: $e');
        });
      },
      transactionsUpdated: (dto) {
        printV('Transactions updated: ${dto.updatedTransactions.length} transactions');
        // Update existing transactions (fire-and-forget)
        _processNewTransactions(dto.updatedTransactions).catchError((e) {
          printV('Error processing updated transactions: $e');
        });
      },
      error: (errorMessage) {
        printV('Scanner error: $errorMessage');
        syncStatus = FailedSyncStatus();
      },
    );
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final creds = credentials as MinotariTransactionCredentials;

    // Validate we have seed words
    final mnemonic = _mnemonic;
    if (mnemonic == null || mnemonic.isEmpty) {
      throw Exception('Wallet seed not available. Cannot create transaction.');
    }

    // Validate we have a connected node
    final currentNode = _currentNode;
    if (currentNode == null) {
      throw Exception('No node connected. Call connectToNode first.');
    }

    // Validate FFI is initialized
    final ffi = _ffi;
    if (ffi == null) {
      throw Exception('Wallet not initialized.');
    }

    // Get the first output (Minotari doesn't support multiple outputs yet)
    if (creds.outputs.isEmpty) {
      throw Exception('No outputs specified for transaction.');
    }

    final output = creds.outputs.first;
    final recipientAddress = output.isParsedAddress
        ? output.extractedAddress ?? output.address
        : output.address;

    // Calculate amount - handle sendAll and nullable formattedCryptoAmount
    final int amount;
    if (output.sendAll) {
      amount = balance[CryptoCurrency.xtm]?.available ?? 0;
    } else {
      final formattedAmount = output.formattedCryptoAmount;
      if (formattedAmount == null || formattedAmount <= 0) {
        throw Exception('Invalid amount specified.');
      }
      amount = formattedAmount;
    }

    if (amount <= 0) {
      throw Exception('Invalid amount: $amount');
    }

    if (recipientAddress.isEmpty) {
      throw Exception('Recipient address is empty.');
    }

    // Prepare seed words as list
    final seedWords = mnemonic.split(' ').where((w) => w.isNotEmpty).toList();
    if (seedWords.length != 24) {
      throw Exception('Invalid seed: expected 24 words, got ${seedWords.length}');
    }

    final nodeUrl = currentNode.uri.toString();

    // TODO Estimated fee (Minotari calculates actual fee during transaction construction)
    // Use the placeholder estimate from calculateEstimatedFee
    final fee = 27777; // Placeholder fixed fee for Minotari

    // Get note/payment ID if provided
    final note = output.note;
    final paymentId = (note != null && note.isNotEmpty) ? note : null;

    // Create the send transaction callback
    Future<String> sendTransactionCallback() async {
      final completer = Completer<String>();

      final stream = ffi.sendTransaction(
        seedWords: seedWords,
        passphrase: passphrase ?? '',
        recipientAddress: recipientAddress,
        amount: BigInt.from(amount),
        baseNodeUrl: nodeUrl,
        paymentId: paymentId,
      );

      stream.listen(
        (event) {
          printV('Send transaction stage: ${event.stage.name} - ${event.details}');

          if (event.stage == TransactionStage.completed) {
            // The details field contains the transaction ID on completion
            if (!completer.isCompleted) {
              completer.complete(event.details);
            }
          }
        },
        onError: (Object error) {
          printV('Send transaction error: $error');
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          // If stream completes without reaching 'completed' stage, something went wrong
          if (!completer.isCompleted) {
            completer.completeError(Exception('Transaction stream ended unexpectedly'));
          }
        },
        cancelOnError: true,
      );

      // Wait for transaction to complete
      final txId = await completer.future;

      // Update balance and transactions after send
      await updateBalance();
      await updateTransactions();

      return txId;
    }

    return PendingMinotariTransaction(
      amount: amount,
      fee: fee,
      recipientAddress: recipientAddress,
      sendTransaction: sendTransactionCallback,
    );
  }

  @override
  Future<void> save() async {
    // Wallet state is saved automatically by the Rust layer
    // Save the keys file (mnemonic and passphrase)
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(password, encryptionFileUtils);
      saveKeysFile(password, encryptionFileUtils, true); // backup
    }
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
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

  @override
  Future<bool> checkNodeHealth() async {
    // TODO Stub implementation - always return true
    return true;
  }

  @override
  Future<Map<String, MinotariTransactionInfo>> fetchTransactions() async {
    // TODO Stub implementation - return empty map
    return {};
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    // TODO Stub implementation
    throw UnimplementedError('signMessage not yet implemented');
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    // TODO Stub implementation
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
      if (_isTransactionUpdating) return;

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

        final direction = txDto.direction == DisplayedTransactionDirection.incoming
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing;

        final isPending = txDto.status != DisplayedTransactionStatus.confirmed;
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

        // Store additional data in additionalInfo map for transaction details display
        txInfo.additionalInfo['source'] = txDto.source.name;
        txInfo.additionalInfo['status'] = txDto.status.name;
        txInfo.additionalInfo['amountDisplay'] = txDto.amountDisplay;

        if (txDto.message != null && txDto.message!.isNotEmpty) {
          txInfo.additionalInfo['message'] = txDto.message!;
        }

        if (txDto.fee != null) {
          txInfo.additionalInfo['feeDisplay'] = txDto.fee!.amountDisplay;
        }

        if (txDto.counterparty != null) {
          txInfo.additionalInfo['counterpartyAddress'] = txDto.counterparty!.address;
          if (txDto.counterparty!.addressEmoji != null) {
            txInfo.additionalInfo['counterpartyEmoji'] = txDto.counterparty!.addressEmoji!;
          }
          if (txDto.counterparty!.label != null && txDto.counterparty!.label!.isNotEmpty) {
            txInfo.additionalInfo['counterpartyLabel'] = txDto.counterparty!.label!;
          }
        }

        transactionHistory.transactions[txDto.id] = txInfo;
      } catch (e) {
        printV('Error processing transaction: $e');
      }
    }

    await transactionHistory.save();
  }
}
