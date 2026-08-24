import 'dart:async';
import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/amount/money_double.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/solana_rpc_http_service.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_exceptions.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:cw_core/spl_token.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain/solana/src/instructions/associated_token_account/constant.dart';
import 'package:on_chain/solana/src/models/pda/pda.dart';
import 'package:on_chain/solana/src/rpc/models/models/confirmed_transaction_meta.dart';
import '.secrets.g.dart' as secrets;

/// Result object containing both parsed transactions and token mints
class TransactionFetchResult {
  final List<SolanaTransactionModel> transactions;
  final List<String> tokenMints;

  TransactionFetchResult({
    required this.transactions,
    required this.tokenMints,
  });
}

class TransactionSyncResult {
  final List<SolanaTransactionModel> transactions;
  final String? newestSignature;

  TransactionSyncResult({
    required this.transactions,
    this.newestSignature,
  });
}

class SolanaWalletClient {
  // Minimum amount in SOL to consider a transaction valid (to filter spam)
  static Money minValidAmount = Money.parse("0.00000003", CryptoCurrency.sol);

  static const int _signaturePageSize = 1000;

  late final client = ProxyWrapper().getHttpIOClient();
  SolanaRPC? _provider;
  bool _isStopped = false;

  final Map<String, bool> _jupiterVerificationCache = {};

  bool connect(Node node) {
    try {
      _isStopped = false;
      String formattedUrl;
      String protocolUsed = node.isSSL ? "https" : "http";

      if (node.uriRaw == 'rpc.ankr.com') {
        String ankrApiKey = secrets.ankrApiKey;

        formattedUrl = '$protocolUsed://${node.uriRaw}/$ankrApiKey';
      } else if (node.uriRaw == 'solana-mainnet.core.chainstack.com') {
        String chainStackApiKey = secrets.chainStackApiKey;

        formattedUrl = '$protocolUsed://${node.uriRaw}/$chainStackApiKey';
      } else {
        formattedUrl = '$protocolUsed://${node.uriRaw}';
      }

      _provider = SolanaRPC(SolanaRPCHTTPService(url: formattedUrl));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Money> getBalance(String walletAddress, {bool throwOnError = false}) async {
    try {
      final balance = await _provider!.requestWithContext(
        SolanaRPCGetBalance(account: SolAddress(walletAddress)),
      );
      return Money(balance.result, CryptoCurrency.sol);
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return Money.zero(CryptoCurrency.sol);
    }
  }

  Future<List<TokenAccountResponse>?> getSPLTokenAccounts(
      String mintAddress, String publicKey) async {
    try {
      final result = await _provider!.request(
        SolanaRPCGetTokenAccountsByOwner(
          account: SolAddress(publicKey),
          mint: SolAddress(mintAddress),
          commitment: Commitment.confirmed,
          encoding: SolanaRPCEncoding.base64,
        ),
      );

      return result;
    } catch (e) {
      return null;
    }
  }

  Future<SolanaBalance?> getSplTokenBalance(SPLToken token, String walletAddress,
      {bool throwOnError = false}) async {
    try {
      // Fetch the token accounts (a token can have multiple accounts for various uses)
      final tokenAccounts = await getSPLTokenAccounts(token.mintAddress, walletAddress);

      // Handle scenario where there is no token account
      if (tokenAccounts == null || tokenAccounts.isEmpty) {
        return null;
      }

      // Sum raw amounts and ui amounts across all token accounts
      var totalRaw = BigInt.zero;

      for (var tokenAccount in tokenAccounts) {
        final tokenAmountResult = await _provider!.request(
          SolanaRPCGetTokenAccountBalance(account: tokenAccount.pubkey),
        );

        final raw = BigInt.tryParse(tokenAmountResult.amount) ?? BigInt.zero;
        totalRaw += raw;
      }

      return SolanaBalance(Money(totalRaw, token));
    } catch (_) {
      if (throwOnError) rethrow;

      return null;
    }
  }

  Future<Money> getFeeForMessage(String message, Commitment commitment) async {
    try {
      final feeForMessage = await _provider!.request(
        SolanaRPCGetFeeForMessage(encodedMessage: message, commitment: commitment),
      );

      return Money(feeForMessage ?? BigInt.zero, CryptoCurrency.sol);
    } catch (_) {
      return Money.zero(CryptoCurrency.sol);
    }
  }

  Future<Money> getEstimatedFee(SolanaPublicKey publicKey, Commitment commitment) async {
    final message = await _getMessageForNativeTransaction(
      publicKey: publicKey,
      destinationAddress: publicKey.toAddress().address,
      lamports: Money(BigInt.from(1000000000), CryptoCurrency.sol),
      commitment: commitment,
    );

    return _getFeeFromCompiledMessage(message, commitment);
  }

  Future<List<SolanaTransactionModel>?> parseTransaction({
    VersionedTransactionResponse? txResponse,
    required String walletAddress,
    SPLToken? splToken,
  }) async {
    if (txResponse == null) return null;

    try {
      final blockTime = txResponse.blockTime;
      final meta = txResponse.meta;
      final transaction = txResponse.transaction;

      if (meta == null || transaction == null) return null;

      final fee = meta.fee;

      final message = transaction.message;
      final instructions = message.compiledInstructions;

      String signature = (txResponse.transaction?.signatures.isEmpty ?? true)
          ? ""
          : Base58Encoder.encode(txResponse.transaction!.signatures.first);

      // We need to check if this is a swap transaction (both native SOL and SPL token balance changes)
      final isSwap = _isSwapTransaction(meta, message, walletAddress);

      if (isSwap) {
        // We parse it separately, because we want to extract two separate transactions, the outgoing and incoming side of the swap
        final swapTransactions = await _parseSwapTransaction(
          message: message,
          meta: meta,
          fee: fee,
          walletAddress: walletAddress,
          signature: signature,
          blockTime: blockTime,
          instructions: instructions,
        );

        if (swapTransactions.isNotEmpty) return swapTransactions;
      }

      for (final instruction in instructions) {
        final programId = message.accountKeys[instruction.programIdIndex];

        if (programId == SystemProgramConst.programId ||
            programId == ComputeBudgetConst.programId) {
          // For native solana transactions
          if (instruction.accounts.length < 2) continue;

          // Get the fee payer index based on transaction type
          // For legacy transfers, the first account is usually the fee payer
          // For versioned, the first account in instruction is usually the fee payer
          final feePayerIndex =
              txResponse.version == TransactionType.legacy ? 0 : instruction.accounts[0];

          final transactionModel = await _parseNativeTransaction(
            message: message,
            meta: meta,
            fee: fee,
            feePayerIndex: feePayerIndex,
            walletAddress: walletAddress,
            signature: signature,
            blockTime: blockTime,
          );

          if (transactionModel != null) {
            return [transactionModel];
          }
        } else if (programId == SPLTokenProgramConst.tokenProgramId) {
          // For SPL Token transactions
          if (instruction.accounts.length < 2) continue;

          final transactionModel = await _parseSPLTokenTransaction(
            message: message,
            meta: meta,
            fee: fee,
            instruction: instruction,
            walletAddress: walletAddress,
            signature: signature,
            blockTime: blockTime,
            splToken: splToken,
          );

          if (transactionModel != null) {
            return [transactionModel];
          }
        } else if (programId == AssociatedTokenAccountProgramConst.associatedTokenProgramId) {
          // For ATA program, we need to check if this is a create account transaction
          // or if it's part of a normal token transfer

          // We skip this transaction if this is the only instruction (this means that it's a create account transaction)
          if (instructions.length == 1) {
            return null;
          }

          // We look for a token transfer instruction in the same transaction
          bool hasTokenTransfer = false;
          for (final otherInstruction in instructions) {
            final otherProgramId = message.accountKeys[otherInstruction.programIdIndex];
            if (otherProgramId == SPLTokenProgramConst.tokenProgramId) {
              hasTokenTransfer = true;
              break;
            }
          }

          // If there's no token transfer instruction, it means this is just an ATA creation transaction
          if (!hasTokenTransfer) {
            return null;
          }

          continue;
        } else {
          continue;
        }
      }
    } catch (e, s) {
      printV("Error parsing transaction: $e\n$s");
    }

    return null;
  }

  /// Detects if a transaction is a swap by checking that the wallet both sends one asset and receives another.
  ///
  /// A simple token transfer is NOT a swap (wallet only sends or receives, not both).
  bool _isSwapTransaction(
    ConfirmedTransactionMeta meta,
    VersionedMessage message,
    String walletAddress,
  ) {
    final fee = meta.fee;
    final preBalances = meta.preBalances;
    final postBalances = meta.postBalances;
    final accountKeys = message.accountKeys;

    bool walletSentSol = false;
    bool walletReceivedSol = false;

    if (preBalances.isNotEmpty && postBalances.isNotEmpty) {
      final maxLength = [
        accountKeys.length,
        preBalances.length,
        postBalances.length,
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < maxLength; i++) {
        if (accountKeys[i].address != walletAddress) {
          continue;
        }

        final change = postBalances[i] - preBalances[i];

        if (change > BigInt.zero) {
          walletReceivedSol = true;
        } else if (change < BigInt.zero) {
          // Only count as sent if the decrease
          // exceeds the fee (otherwise it's just fees).
          final netDecrease = change.abs() - BigInt.from(fee);
          if (netDecrease > BigInt.zero) {
            walletSentSol = true;
          }
        }
        break;
      }
    }

    bool walletSentToken = false;
    bool walletReceivedToken = false;

    final preTokenBalances = meta.preTokenBalances;
    final postTokenBalances = meta.postTokenBalances;

    if (preTokenBalances != null && postTokenBalances != null) {
      // Check wallet-owned balances that exist in pre
      for (final preBal in preTokenBalances) {
        if (preBal.owner?.address != walletAddress) {
          continue;
        }

        final mint = preBal.mint.address;
        final preAmt = preBal.uiTokenAmount.uiAmount ?? 0.0;

        double postAmt = preAmt;
        for (final postBal in postTokenBalances) {
          if (postBal.owner?.address == walletAddress && postBal.mint.address == mint) {
            postAmt = postBal.uiTokenAmount.uiAmount ?? 0.0;
            break;
          }
        }

        final diff = postAmt - preAmt;
        if (diff < 0) {
          walletSentToken = true;
        } else if (diff > 0) {
          walletReceivedToken = true;
        }
      }

      // Check for tokens the wallet received into
      // a newly created ATA (no pre-balance entry).
      for (final postBal in postTokenBalances) {
        if (postBal.owner?.address != walletAddress) {
          continue;
        }
        final postAmt = postBal.uiTokenAmount.uiAmount ?? 0.0;
        if (postAmt <= 0) continue;

        final mint = postBal.mint.address;
        final existsInPre = preTokenBalances.any(
          (p) => p.owner?.address == walletAddress && p.mint.address == mint,
        );
        if (!existsInPre) {
          walletReceivedToken = true;
        }
      }
    }

    // A swap requires the wallet to both send and receive across different assets.
    final walletSent = walletSentSol || walletSentToken;
    final walletReceived = walletReceivedSol || walletReceivedToken;
    return walletSent && walletReceived;
  }

  /// Parses a swap transaction and creates dual entries (outgoing and incoming)
  Future<List<SolanaTransactionModel>> _parseSwapTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
    required List<CompiledInstruction> instructions,
  }) async {
    final List<SolanaTransactionModel> swapTransactions = [];

    final preBalances = meta.preBalances;
    final postBalances = meta.postBalances;
    final accountKeys = message.accountKeys;
    final preTokenBalances = meta.preTokenBalances;
    final postTokenBalances = meta.postTokenBalances;

    String? decreasedMintForWallet;
    String? increasedMintForWallet;

    if (preTokenBalances != null && postTokenBalances != null) {
      for (final preTokenBal in preTokenBalances) {
        final owner = preTokenBal.owner?.address ?? '';
        if (owner != walletAddress) continue;

        final mint = preTokenBal.mint.address;
        final preAmount = preTokenBal.uiTokenAmount.uiAmount ?? 0.0;

        double postAmount = preAmount;
        for (final postTokenBal in postTokenBalances) {
          final postOwner = postTokenBal.owner?.address ?? '';
          final postMint = postTokenBal.mint.address;
          if (postOwner == walletAddress && postMint == mint) {
            postAmount = postTokenBal.uiTokenAmount.uiAmount ?? 0.0;
            break;
          }
        }

        final diff = postAmount - preAmount;
        if (diff < 0 && decreasedMintForWallet == null) {
          decreasedMintForWallet = mint;
        } else if (diff > 0 && increasedMintForWallet == null) {
          increasedMintForWallet = mint;
        }
      }
    }

    final bool isSplToSplSwap = decreasedMintForWallet != null &&
        increasedMintForWallet != null &&
        decreasedMintForWallet != increasedMintForWallet;

    // Parse outgoing side (what was sent)
    double outgoingAmount = 0.0;
    Currency outgoingToken = CryptoCurrency.sol;
    String? outgoingMintAddress;
    String? outgoingFrom;
    String? outgoingTo;

    // First we check if there are any native SOL balance changes for the wallet.
    // For pure SPL → SPL swaps, SOL changes are just fees, so we ignore them.
    if (!isSplToSplSwap && preBalances.isNotEmpty && postBalances.isNotEmpty) {
      final maxLength =
          accountKeys.length < preBalances.length ? accountKeys.length : preBalances.length;

      for (int i = 0; i < maxLength && i < postBalances.length; i++) {
        final accountKey = accountKeys[i];
        final accountAddress = accountKey.address;

        if (accountAddress == walletAddress) {
          final preBalance = preBalances[i];
          final postBalance = postBalances[i];
          final balanceChange = preBalance - postBalance;

          if (balanceChange > BigInt.zero) {
            // The wallet sent SOL
            outgoingAmount = balanceChange.toDouble() / SolanaUtils.lamportsPerSol;
            outgoingToken = CryptoCurrency.sol;
            outgoingMintAddress = null;
            outgoingFrom = walletAddress;
            // We find the intermediate account or swap program account
            if (instructions.isNotEmpty && instructions[0].accounts.isNotEmpty) {
              final firstAccountIndex = instructions[0].accounts[0];
              if (firstAccountIndex < accountKeys.length) {
                outgoingTo = accountKeys[firstAccountIndex].address;
              }
            }
            outgoingTo ??= walletAddress;
            break;
          }
        }
      }
    }

    // If no SOL outgoing, we check if there are any SPL token balance changes for the wallet
    if (outgoingAmount == 0.0 && preTokenBalances != null) {
      for (final preTokenBal in preTokenBalances) {
        final owner = preTokenBal.owner?.address ?? '';

        if (owner == walletAddress) {
          final mint = preTokenBal.mint.address;
          // For SPL → SPL swaps, we only treat the decreased mint as outgoing
          if (isSplToSplSwap && mint != decreasedMintForWallet) {
            continue;
          }
          final preAmount = preTokenBal.uiTokenAmount.uiAmount ?? 0.0;

          // We find the corresponding post balance
          for (final postTokenBal in postTokenBalances ?? []) {
            final postOwner = postTokenBal.owner?.address ?? '';
            final postMint = postTokenBal.mint.address;
            final postAmount = postTokenBal.uiTokenAmount.uiAmount ?? 0.0;

            if (postOwner == walletAddress && postMint == mint) {
              final diff = preAmount - postAmount;

              if (diff > 0) {
                // The wallet sent tokens
                outgoingAmount = diff.toDouble();
                outgoingMintAddress = mint;
                final token = await getTokenInfo(mint);
                outgoingToken =
                    token ?? const CryptoCurrency(name: "TOKEN", title: "TOKEN", decimals: 6);
                outgoingFrom = walletAddress;
                // We find the intermediate account
                if (instructions.isNotEmpty && instructions[0].accounts.isNotEmpty) {
                  final firstAccountIndex = instructions[0].accounts[0];
                  if (firstAccountIndex < accountKeys.length) {
                    outgoingTo = accountKeys[firstAccountIndex].address;
                  }
                }
                outgoingTo ??= walletAddress;
                break;
              }
            }
          }

          if (outgoingAmount > 0) break;
        }
      }
    }

    // Parse incoming side (what was received)
    double incomingAmount = 0.0;
    Currency incomingToken = CryptoCurrency.sol;
    String? incomingMintAddress;
    String? incomingFrom;
    String? incomingTo;

    // We check if there are any native SOL balance changes for the wallet
    if (preBalances.isNotEmpty && postBalances.isNotEmpty) {
      final maxLength =
          accountKeys.length < preBalances.length ? accountKeys.length : preBalances.length;

      for (int i = 0; i < maxLength && i < postBalances.length; i++) {
        final accountKey = accountKeys[i];
        final accountAddress = accountKey.address;

        if (accountAddress == walletAddress) {
          final preBalance = preBalances[i];
          final postBalance = postBalances[i];
          final balanceChange = postBalance - preBalance;

          if (balanceChange > BigInt.zero) {
            // The wallet received SOL
            incomingAmount = balanceChange.toDouble() / SolanaUtils.lamportsPerSol;
            incomingToken = CryptoCurrency.sol;
            incomingMintAddress = null;
            incomingTo = walletAddress;
            // We find the intermediate account
            if (instructions.isNotEmpty && instructions[0].accounts.isNotEmpty) {
              final firstAccountIndex = instructions[0].accounts[0];
              if (firstAccountIndex < accountKeys.length) {
                incomingFrom = accountKeys[firstAccountIndex].address;
              }
            }
            incomingFrom ??= walletAddress;
            break;
          }
        }
      }
    }

    // If no SOL incoming, check SPL token incoming using ATA derivation
    if (incomingAmount == 0.0 && preTokenBalances != null && postTokenBalances != null) {
      // Collect all unique mints from token balances (excluding wrapped SOL)
      final mints = <String>{};
      for (final tokenBal in preTokenBalances) {
        final mint = tokenBal.mint.address;
        if (mint != 'So11111111111111111111111111111111111111112') {
          mints.add(mint);
        }
      }
      for (final tokenBal in postTokenBalances) {
        final mint = tokenBal.mint.address;
        if (mint != 'So11111111111111111111111111111111111111112') {
          mints.add(mint);
        }
      }

      // For each mint, we derive the wallet's ATA address and check for balance changes
      for (final mint in mints) {
        try {
          final walletSolAddress = SolAddress(walletAddress);
          final mintSolAddress = SolAddress(mint);

          final ata = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
            mint: mintSolAddress,
            owner: walletSolAddress,
          );
          final ataAddress = ata.address.address;

          // We check if this ATA address appears in the account keys
          int? ataAccountIndex;
          for (int i = 0; i < accountKeys.length; i++) {
            final accountKey = accountKeys[i];
            if (accountKey.address == ataAddress) {
              ataAccountIndex = i;
              break;
            }
          }

          // If ATA is in the transaction, we check for balance changes
          if (ataAccountIndex != null) {
            double preAmount = 0.0;
            double postAmount = 0.0;

            // We find the pre balance
            for (final preTokenBal in preTokenBalances) {
              final accountIndex = preTokenBal.accountIndex;
              final tokenMint = preTokenBal.mint.address;
              if (accountIndex == ataAccountIndex && tokenMint == mint) {
                preAmount = preTokenBal.uiTokenAmount.uiAmount?.toDouble() ?? 0.0;
                break;
              }
            }

            // We find the post balance
            for (final postTokenBal in postTokenBalances) {
              final accountIndex = postTokenBal.accountIndex;
              final tokenMint = postTokenBal.mint.address;
              if (accountIndex == ataAccountIndex && tokenMint == mint) {
                postAmount = postTokenBal.uiTokenAmount.uiAmount?.toDouble() ?? 0.0;
                break;
              }
            }

            final diff = postAmount - preAmount;
            if (diff > 0) {
              // The wallet received tokens
              incomingAmount = diff.toDouble();
              incomingMintAddress = mint;
              final token = await getTokenInfo(mint);
              incomingToken = token ?? const CryptoCurrency(name: "TOKEN", title: "TOKEN", decimals: 6);
              incomingTo = walletAddress;
              // We find the intermediate account
              if (instructions.isNotEmpty && instructions[0].accounts.isNotEmpty) {
                final firstAccountIndex = instructions[0].accounts[0];
                if (firstAccountIndex < accountKeys.length) {
                  incomingFrom = accountKeys[firstAccountIndex].address;
                }
              }
              incomingFrom ??= walletAddress;
              break;
            }
          }
        } catch (e) {
          // We skip if the ATA derivation fails
          continue;
        }
      }
    }

    // Outgoing transaction model
    if (outgoingAmount > 0.0 && outgoingFrom != null && outgoingTo != null) {
      final outgoingId =
          '${signature}_outgoing'; // We create a composite ID for the outgoing transaction
      swapTransactions.add(SolanaTransactionModel(
        isOutgoingTx: true,
        from: outgoingFrom,
        to: outgoingTo,
        id: outgoingId,
        amount: outgoingAmount.toMoney(outgoingToken),
        programId: outgoingMintAddress == null
            ? SystemProgramConst.programId.address
            : SPLTokenProgramConst.tokenProgramId.address,
        blockTimeInInt: blockTime?.toInt() ?? 0,
        fee: Money.fromInt(fee, CryptoCurrency.sol),
      ));
    }

    // Incoming transaction model
    if (incomingAmount > 0.0 && incomingFrom != null && incomingTo != null) {
      final incomingId =
          '${signature}_incoming'; // We create a composite ID for the incoming transaction
      swapTransactions.add(SolanaTransactionModel(
        isOutgoingTx: false,
        from: incomingFrom,
        to: incomingTo,
        id: incomingId,
        amount: incomingAmount.toMoney(incomingToken),
        programId: incomingMintAddress == null
            ? SystemProgramConst.programId.address
            : SPLTokenProgramConst.tokenProgramId.address,
        blockTimeInInt: blockTime?.toInt() ?? 0,
        fee: Money.zero(CryptoCurrency.sol), // Fee only charged on outgoing side
      ));
    }

    return swapTransactions;
  }

  Future<SolanaTransactionModel?> _parseNativeTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required int feePayerIndex,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
  }) async {
    final accountKeys = message.accountKeys;
    final preBalances = meta.preBalances;
    final postBalances = meta.postBalances;

    final maxLen = [
      accountKeys.length,
      preBalances.length,
      postBalances.length,
    ].reduce((a, b) => a < b ? a : b);

    // Find the wallet's own balance change.
    int walletIndex = -1;
    for (int i = 0; i < maxLen; i++) {
      if (accountKeys[i].address == walletAddress) {
        walletIndex = i;
        break;
      }
    }

    if (walletIndex < 0) return null;

    final walletPre = preBalances[walletIndex];
    final walletPost = postBalances[walletIndex];
    // Positive = wallet lost SOL, negative = wallet gained.
    final walletChange = walletPre - walletPost;

    final bool walletPaidFee =
        feePayerIndex < accountKeys.length && accountKeys[feePayerIndex].address == walletAddress;

    // Net transfer amount excluding the fee.
    final netChange = walletPaidFee ? walletChange - BigInt.from(fee) : walletChange;

    final isOutgoing = netChange > BigInt.zero;
    final amountLamports = Money(netChange.abs(), CryptoCurrency.sol);

    if (amountLamports < minValidAmount) return null;

    // Find the most likely receiver, the account that has the largest opposite balance change.
    String? receiver;
    BigInt bestChange = BigInt.zero;

    for (int i = 0; i < maxLen; i++) {
      if (i == walletIndex) continue;
      final change = postBalances[i] - preBalances[i];

      if (isOutgoing && change > bestChange) {
        bestChange = change;
        receiver = accountKeys[i].address;
      } else if (!isOutgoing && change < BigInt.zero && change.abs() > bestChange) {
        bestChange = change.abs();
        receiver = accountKeys[i].address;
      }
    }

    if (receiver == null) return null;

    return SolanaTransactionModel(
      isOutgoingTx: isOutgoing,
      from: isOutgoing ? walletAddress : receiver,
      to: isOutgoing ? receiver : walletAddress,
      id: signature,
      amount: amountLamports,
      programId: SystemProgramConst.programId.address,
      blockTimeInInt: blockTime?.toInt() ?? 0,
      fee: Money.fromInt(fee, CryptoCurrency.sol),
    );
  }

  Future<SolanaTransactionModel?> _parseSPLTokenTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required CompiledInstruction instruction,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
    SPLToken? splToken,
  }) async {
    final preTokenBalances = meta.preTokenBalances;
    final postTokenBalances = meta.postTokenBalances;

    final accountKeys = message.accountKeys;
    final accounts = instruction.accounts;

    // TransferChecked has 4 accounts:
    //   [0] source, [1] mint, [2] destination, [3] owner
    // Transfer has 3 accounts:
    //   [0] source, [1] destination, [2] owner
    final isTransferChecked = accounts.length >= 4;

    final sourceAccountIndex = accounts[0];
    final destinationAccountIndex = isTransferChecked ? accounts[2] : accounts[1];

    String? mintAddress;
    if (isTransferChecked) {
      mintAddress = accountKeys[accounts[1]].address;
    }

    double userPreAmount = 0.0;
    double userPostAmount = 0.0;

    if (preTokenBalances != null) {
      for (final preBal in preTokenBalances) {
        final idx = preBal.accountIndex;
        if (idx == sourceAccountIndex || idx == destinationAccountIndex) {
          if (preBal.owner?.address == walletAddress) {
            if (mintAddress != null && preBal.mint.address != mintAddress) {
              continue;
            }
            mintAddress ??= preBal.mint.address;
            userPreAmount = preBal.uiTokenAmount.uiAmount ?? 0.0;
            break;
          }
        }
      }
    }

    if (postTokenBalances != null) {
      for (final postBal in postTokenBalances) {
        final idx = postBal.accountIndex;
        if (idx == sourceAccountIndex || idx == destinationAccountIndex) {
          if (postBal.owner?.address == walletAddress) {
            if (mintAddress != null && postBal.mint.address != mintAddress) {
              continue;
            }
            mintAddress ??= postBal.mint.address;
            userPostAmount = postBal.uiTokenAmount.uiAmount ?? 0.0;
            break;
          }
        }
      }
    }

    final diff = userPreAmount - userPostAmount;
    final rawAmount = diff.abs();

    final amountInString = rawAmount.toStringAsFixed(6);
    final amount = double.parse(amountInString);
    final isOutgoing = diff > 0;

    // Resolve sender/receiver from token balance owners
    String? senderOwner;
    String? receiverOwner;

    final allBalances = [
      ...?preTokenBalances,
      ...?postTokenBalances,
    ];

    for (final bal in allBalances) {
      if (mintAddress != null && bal.mint.address != mintAddress) {
        continue;
      }
      if (bal.accountIndex == sourceAccountIndex) {
        senderOwner ??= bal.owner?.address;
      }
      if (bal.accountIndex == destinationAccountIndex) {
        receiverOwner ??= bal.owner?.address;
      }
      if (senderOwner != null && receiverOwner != null) {
        break;
      }
    }

    final sender = senderOwner ?? accountKeys[sourceAccountIndex].address;
    final receiver = receiverOwner ?? accountKeys[destinationAccountIndex].address;

    if (splToken == null && mintAddress != null) {
      splToken = await getTokenInfo(mintAddress);
    }

    return SolanaTransactionModel(
      isOutgoingTx: isOutgoing,
      from: sender,
      to: receiver,
      id: signature,
      amount: amount.toMoney(splToken ?? CryptoCurrency.sol),
      programId: SPLTokenProgramConst.tokenProgramId.address,
      blockTimeInInt: blockTime?.toInt() ?? 0,
      fee: Money.fromInt(fee, CryptoCurrency.sol),
    );
  }

  /// Fetches a specific transaction by signature and parses it
  /// It returns a TransactionFetchResult object containing both transactions and token mints
  /// extracted from the transaction or null if the transaction is not found or cannot be parsed
  Future<TransactionFetchResult?> fetchTransactionBySignature({
    required String signature,
    required String walletAddress,
    SPLToken? splToken,
  }) async {
    try {
      final txResponse = await _provider!.request(
        SolanaRPCGetTransaction(
          transactionSignature: signature,
          encoding: SolanaRPCEncoding.jsonParsed,
          maxSupportedTransactionVersion: 1,
          skipVerification: true,
        ),
      );

      final versionedResponse = txResponse as VersionedTransactionResponse?;
      if (versionedResponse == null) return null;

      final tokenMints = _extractTokenMintsFromMeta(versionedResponse.meta);

      final parsed = await parseTransaction(
        txResponse: versionedResponse,
        walletAddress: walletAddress,
        splToken: splToken,
      );

      if (parsed == null) return null;

      return TransactionFetchResult(
        transactions: parsed,
        tokenMints: tokenMints,
      );
    } catch (e) {
      printV('Error fetching transaction by signature: $e');
      return null;
    }
  }

  /// Extracts token mint addresses from transaction metadata
  /// It returns a list of unique token mint addresses (excluding wrapped SOL)
  List<String> _extractTokenMintsFromMeta(ConfirmedTransactionMeta? meta) {
    if (meta == null) return [];

    final preTokenBalances = meta.preTokenBalances;
    final postTokenBalances = meta.postTokenBalances;

    final mints = <String>{};

    if (preTokenBalances != null) {
      for (final tokenBal in preTokenBalances) {
        final mint = tokenBal.mint.address;
        if (mint != 'So11111111111111111111111111111111111111112') {
          mints.add(mint);
        }
      }
    }

    if (postTokenBalances != null) {
      for (final tokenBal in postTokenBalances) {
        final mint = tokenBal.mint.address;
        if (mint != 'So11111111111111111111111111111111111111112') {
          mints.add(mint);
        }
      }
    }

    return mints.toList();
  }

  Future<List<Map<String, dynamic>>> _getAllSignaturesSinceLastFetch(
    SolAddress address,
    String? until,
    Commitment? commitment,
  ) async {
    final signatures = <Map<String, dynamic>>[];
    String? before;

    while (true) {
      final currentPageSignatureResults = await _provider!.request(
        SolanaRPCGetSignaturesForAddress(
          account: address,
          commitment: commitment,
          until: until,
          before: before,
          limit: _signaturePageSize,
        ),
      );

      if (currentPageSignatureResults.isEmpty) break;

      signatures.addAll(currentPageSignatureResults);

      if (currentPageSignatureResults.length < _signaturePageSize) break;

      if (until == null) break;

      final lastSignatureOnPage = currentPageSignatureResults.last['signature'] as String;

      if (lastSignatureOnPage == before) break;

      before = lastSignatureOnPage;
    }

    return signatures;
  }

  Future<TransactionSyncResult> fetchTransactions(
    SolAddress address, {
    SPLToken? splToken,
    Commitment? commitment,
    SolAddress? walletAddress,
    String? untilSignature,
    required void Function(List<SolanaTransactionModel>) onUpdate,
  }) async {
    final transactions = <SolanaTransactionModel>[];

    try {
      final signatures =
          await _getAllSignaturesSinceLastFetch(address, untilSignature, commitment);

      if (signatures.isEmpty) return TransactionSyncResult(transactions: transactions);

      // The maximum concurrent batch size.
      const int batchSize = 10;

      bool hasFailures = false;

      for (int i = 0; i < signatures.length; i += batchSize) {
        if (_isStopped) return TransactionSyncResult(transactions: transactions);

        final batch = signatures.skip(i).take(batchSize).toList();

        final batchResponses = await Future.wait(batch.map((signature) async {
          try {
            return await _provider!.request(
              SolanaRPCGetTransaction(
                transactionSignature: signature['signature'],
                encoding: SolanaRPCEncoding.jsonParsed,
                maxSupportedTransactionVersion: 1,
                skipVerification: true,
              ),
            );
          } catch (e) {
            hasFailures = true;
            return null;
          }
        }));

        final versionedBatchResponses = batchResponses.whereType<VersionedTransactionResponse>();

        final parsedTransactionsFutures = versionedBatchResponses.map((tx) => parseTransaction(
              txResponse: tx,
              splToken: splToken,
              walletAddress: walletAddress?.address ?? address.address,
            ));

        final parsedTransactionsLists = await Future.wait(parsedTransactionsFutures);

        final batchTransactions = <SolanaTransactionModel>[];
        for (final parsedList in parsedTransactionsLists) {
          if (parsedList != null) {
            batchTransactions.addAll(parsedList);
          }
        }

        if (batchTransactions.isNotEmpty) {
          transactions.addAll(batchTransactions);
          onUpdate(batchTransactions);
        }

        if (i + batchSize < signatures.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return TransactionSyncResult(
        transactions: transactions,
        newestSignature: hasFailures ? null : signatures.first['signature'] as String,
      );
    } catch (err, s) {
      printV('Error fetching transactions: $err \n$s');
      return TransactionSyncResult(transactions: transactions);
    }
  }

  final Map<String, ProgramDerivedAddress> associatedTokenAccountCache = {};

  Future<TransactionSyncResult> getSPLTokenTransfers({
    required String mintAddress,
    required SPLToken splToken,
    required SolanaPrivateKey privateKey,
    String? untilSignature,
    required void Function(List<SolanaTransactionModel>) onUpdate,
  }) async {
    final ownerWalletAddress = privateKey.publicKey().toAddress();

    var associatedTokenAccount = associatedTokenAccountCache[mintAddress];

    if (associatedTokenAccount == null) {
      try {
        associatedTokenAccount = await _getOrCreateAssociatedTokenAccount(
          payerPrivateKey: privateKey,
          mintAddress: SolAddress(mintAddress),
          ownerAddress: ownerWalletAddress,
          shouldCreateATA: false,
        );
      } catch (e, s) {
        printV('$e \n $s');
      }

      if (associatedTokenAccount == null) {
        return TransactionSyncResult(transactions: <SolanaTransactionModel>[]);
      }

      associatedTokenAccountCache[mintAddress] = associatedTokenAccount;
    }

    return fetchTransactions(
      associatedTokenAccount.address,
      splToken: splToken,
      walletAddress: ownerWalletAddress,
      untilSignature: untilSignature,
      onUpdate: onUpdate,
    );
  }

  final Map<String, SPLToken?> tokenInfoCache = {};

  Future<SPLToken?> getTokenInfo(String mintAddress) async {
    if (tokenInfoCache.containsKey(mintAddress)) return tokenInfoCache[mintAddress];

    return tokenInfoCache[mintAddress] = await fetchSPLTokenInfo(mintAddress);
  }

  Future<SPLToken?> fetchSPLTokenInfo(String mintAddress) async {
    try {
      final uri = Uri.https(
        'solana-gateway.moralis.io',
        '/token/mainnet/$mintAddress/metadata',
      );

      final response = await client.get(
        uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      );

      if (response.statusCode != 200) return null;
      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      final symbol = decodedResponse['symbol'] ?? '';
      final name = decodedResponse['name'] ?? '';
      final decimal = decodedResponse['decimals'] ?? '0';
      final iconPath = decodedResponse['logo'] ?? '';

      final filteredTokenSymbol = symbol.replaceFirst(RegExp('^\\\$'), '').replaceAll('\u0000', '');

      return SPLToken(
        name: name,
        mint: symbol,
        symbol: filteredTokenSymbol,
        mintAddress: mintAddress,
        iconPath: iconPath,
        decimal: int.tryParse(decimal) ?? 0,
      );
    } catch (e, s) {
      printV('Error fetching token info: $e \n $s');
      try {
        final programAddress =
            MetaplexTokenMetaDataProgramUtils.findMetadataPda(mint: SolAddress(mintAddress));

        final token = await _provider!.request(
          SolanaRPCGetMetadataAccount(
            account: programAddress.address,
            commitment: Commitment.confirmed,
          ),
        );

        if (token == null) return null;

        final metadata = token.data;

        String? iconPath;
        //TODO(Further explore fetching images)
        // try {
        //   iconPath = await _client.getIconImageFromTokenUri(metadata.uri);
        // } catch (_) {}

        String filteredTokenSymbol =
            metadata.symbol.replaceFirst(RegExp('^\\\$'), '').replaceAll('\u0000', '');

        return SPLToken.fromMetadata(
          name: metadata.name,
          mint: metadata.symbol,
          symbol: filteredTokenSymbol,
          mintAddress: token.mint.address,
          iconPath: iconPath,
        );
      } catch (_) {}

      return null;
    }
  }

  void stop() => _isStopped = true;

  SolanaRPC? get getSolanaProvider => _provider;

  Future<PendingSolanaTransaction> signSolanaTransaction({
    required Money inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required bool isSendAll,
    required Money solBalance,
    String? tokenMint,
    List<String> references = const [],
  }) async {
    const commitment = Commitment.confirmed;

    if (inputAmount.currency == CryptoCurrency.sol) {
      return _signNativeTokenTransaction(
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerPrivateKey: ownerPrivateKey,
        commitment: commitment,
        isSendAll: isSendAll,
        solBalance: solBalance,
      );
    } else {
      return _signSPLTokenTransaction(
        tokenDecimals: inputAmount.currency.decimals,
        tokenMint: tokenMint!,
        inputAmount: inputAmount,
        ownerPrivateKey: ownerPrivateKey,
        destinationAddress: destinationAddress,
        commitment: commitment,
        solBalance: solBalance,
      );
    }
  }

  Future<SolAddress> _getLatestBlockhash(Commitment commitment) async {
    final latestBlockhash = await _provider!.request(
      const SolanaRPCGetLatestBlockhash(),
    );

    return latestBlockhash.blockhash;
  }

  Future<Message> _getMessageForNativeTransaction({
    required SolanaPublicKey publicKey,
    required String destinationAddress,
    required Money lamports,
    required Commitment commitment,
  }) async {
    final instructions = [
      SystemProgram.transfer(
        from: publicKey.toAddress(),
        layout: SystemTransferLayout(lamports: lamports.amount),
        to: SolAddress(destinationAddress),
      ),
    ];

    final latestBlockhash = await _getLatestBlockhash(commitment);

    return Message.compile(
      transactionInstructions: instructions,
      payer: publicKey.toAddress(),
      recentBlockhash: latestBlockhash,
    );
  }

  Future<Message> _getMessageForSPLTokenTransaction({
    required SolAddress ownerAddress,
    required SolAddress destinationAddress,
    required int tokenDecimals,
    required SolAddress mintAddress,
    required SolAddress sourceAccount,
    required Money amount,
    required Commitment commitment,
    required SolAddress tokenProgramId,
  }) async {
    final instructions = [
      SPLTokenProgram.transferChecked(
        layout: SPLTokenTransferCheckedLayout(
          amount: amount.amount,
          decimals: tokenDecimals,
        ),
        mint: mintAddress,
        source: sourceAccount,
        destination: destinationAddress,
        owner: ownerAddress,
      )
    ];

    final latestBlockhash = await _getLatestBlockhash(commitment);

    return Message.compile(
      transactionInstructions: instructions,
      payer: ownerAddress,
      recentBlockhash: latestBlockhash,
    );
  }

  Future<Money> _getFeeFromCompiledMessage(Message message, Commitment commitment) {
    final base64Message = base64Encode(message.serialize());
    return getFeeForMessage(base64Message, commitment);
  }

  Future<bool> hasSufficientFundsLeftForRent({
    required Money inputAmount,
    required Money solBalance,
    required Money fee,
  }) async {
    final rent = await _provider!.request(
      SolanaRPCGetMinimumBalanceForRentExemption(size: SolanaTokenAccountUtils.accountSize),
    );

    return (solBalance - (inputAmount + fee)) > Money(rent, CryptoCurrency.sol);
  }

  Future<PendingSolanaTransaction> _signNativeTokenTransaction({
    required Money inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required Commitment commitment,
    required bool isSendAll,
    required Money solBalance,
  }) async {
    final message = await _getMessageForNativeTransaction(
      publicKey: ownerPrivateKey.publicKey(),
      destinationAddress: destinationAddress,
      lamports: inputAmount,
      commitment: commitment,
    );

    final latestBlockhash = await _getLatestBlockhash(commitment);

    final fee = await _getFeeFromCompiledMessage(
      message,
      commitment,
    );

    if (!isSendAll) {
      final hasSufficientFundsLeft = await hasSufficientFundsLeftForRent(
        inputAmount: inputAmount,
        fee: fee,
        solBalance: solBalance,
      );

      if (!hasSufficientFundsLeft) {
        throw SolanaSignNativeTokenTransactionRentException();
      }
    }

    String serializedTransaction;
    if (isSendAll) {
      final updatedLamports = inputAmount - fee;

      final transaction = _constructNativeTransaction(
        ownerPrivateKey: ownerPrivateKey,
        destinationAddress: destinationAddress,
        latestBlockhash: latestBlockhash,
        lamports: updatedLamports,
      );

      serializedTransaction = await _signTransactionInternal(
        ownerPrivateKey: ownerPrivateKey,
        transaction: transaction,
      );
    } else {
      final transaction = _constructNativeTransaction(
        ownerPrivateKey: ownerPrivateKey,
        destinationAddress: destinationAddress,
        latestBlockhash: latestBlockhash,
        lamports: inputAmount,
      );

      serializedTransaction = await _signTransactionInternal(
        ownerPrivateKey: ownerPrivateKey,
        transaction: transaction,
      );
    }

    sendTx() async => await sendTransaction(
          serializedTransaction: serializedTransaction,
          commitment: commitment,
        );

    return PendingSolanaTransaction(
      amount: inputAmount,
      serializedTransaction: serializedTransaction,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );
  }

  SolanaTransaction _constructNativeTransaction({
    required SolanaPrivateKey ownerPrivateKey,
    required String destinationAddress,
    required SolAddress latestBlockhash,
    required Money lamports,
  }) {
    final owner = ownerPrivateKey.publicKey().toAddress();

    final transferInstruction = SystemProgram.transfer(
      from: owner,
      layout: SystemTransferLayout(lamports: lamports.amount),
      to: SolAddress(destinationAddress),
    );

    return SolanaTransaction(
      instructions: [transferInstruction],
      recentBlockhash: latestBlockhash,
      payerKey: ownerPrivateKey.publicKey().toAddress(),
      type: TransactionType.v0,
    );
  }

  /// Creates a transferChecked instruction with a custom token program ID.
  /// This supports both standard SPL Token and Token-2022.
  TransactionInstruction _createTransferCheckedInstruction({
    required SolAddress tokenProgramId,
    required SolAddress source,
    required SolAddress destination,
    required SolAddress mint,
    required SolAddress owner,
    required BigInt amount,
    required int decimals,
  }) {
    // TransferChecked instruction format:
    // - Instruction discriminator: 12 (u8)
    // - Amount: 8 bytes (u64, little-endian)
    // - Decimals: 1 byte (u8)

    // Convert BigInt to 8-byte little-endian array
    final amountBytes = <int>[];
    var amountValue = amount.toUnsigned(64);
    for (int i = 0; i < 8; i++) {
      amountBytes.add((amountValue & BigInt.from(0xFF)).toInt());
      amountValue = amountValue >> 8;
    }

    final instructionData = <int>[12, ...amountBytes, decimals];

    // Account order for transferChecked:
    // 0. source (writable)
    // 1. mint (readonly)
    // 2. destination (writable)
    // 3. owner (signer)
    final accounts = [
      AccountMeta(
        publicKey: source,
        isWritable: true,
        isSigner: false,
      ),
      AccountMeta(
        publicKey: mint,
        isWritable: false,
        isSigner: false,
      ),
      AccountMeta(
        publicKey: destination,
        isWritable: true,
        isSigner: false,
      ),
      AccountMeta(
        publicKey: owner,
        isWritable: false,
        isSigner: true,
      ),
    ];

    return TransactionInstruction.fromBytes(
      programId: tokenProgramId,
      instructionBytes: instructionData,
      keys: accounts,
    );
  }

  /// Gets the token program ID for a given mint address.
  /// Returns the standard SPL Token program ID if the mint account cannot be fetched.
  Future<SolAddress> _getTokenProgramId(SolAddress mintAddress) async {
    try {
      final mintAccountInfo = await _provider!.request(
        SolanaRPCGetAccountInfo(
          account: mintAddress,
          commitment: Commitment.confirmed,
        ),
      );

      // Determine the token program ID from the mint account owner
      if (mintAccountInfo != null) {
        return mintAccountInfo.owner;
      }
    } catch (e) {
      // If we can't fetch mint info, default to standard SPL Token program
      printV('Warning: Could not fetch mint account info: $e');
    }

    return SPLTokenProgramConst.tokenProgramId;
  }

  Future<ProgramDerivedAddress?> _getOrCreateAssociatedTokenAccount({
    required SolanaPrivateKey payerPrivateKey,
    required SolAddress ownerAddress,
    required SolAddress mintAddress,
    required bool shouldCreateATA,
  }) async {
    // For transaction history loading (shouldCreateATA: false), try standard token program first
    // to avoid unnecessary RPC call. Only fetch token program ID when creating accounts.
    SolAddress tokenProgramId = SPLTokenProgramConst.tokenProgramId;

    if (shouldCreateATA) {
      // Only fetch token program ID when we need to create an account
      tokenProgramId = await _getTokenProgramId(mintAddress);
    }

    // Try with standard token program first (most common case)
    var associatedTokenAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
      mint: mintAddress,
      owner: ownerAddress,
      tokenProgramId: SPLTokenProgramConst.tokenProgramId,
    );

    SolanaAccountInfo? accountInfo;
    try {
      accountInfo = await _provider!.request(
        SolanaRPCGetAccountInfo(
          account: associatedTokenAccount.address,
          commitment: Commitment.confirmed,
        ),
      );
    } catch (e) {
      accountInfo = null;
    }

    // If account exists with standard program, return it
    if (accountInfo != null) return associatedTokenAccount;

    // If not found and we're not creating, try Token-2022 as fallback
    if (!shouldCreateATA) {
      try {
        final token2022ProgramId = await _getTokenProgramId(mintAddress);
        if (token2022ProgramId.address != SPLTokenProgramConst.tokenProgramId.address) {
          associatedTokenAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
            mint: mintAddress,
            owner: ownerAddress,
            tokenProgramId: token2022ProgramId,
          );

          try {
            accountInfo = await _provider!.request(
              SolanaRPCGetAccountInfo(
                account: associatedTokenAccount.address,
                commitment: Commitment.confirmed,
              ),
            );
            if (accountInfo != null) return associatedTokenAccount;
          } catch (_) {}
        }
      } catch (_) {}
      return null;
    }

    // For account creation, use the detected token program ID
    associatedTokenAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
      mint: mintAddress,
      owner: ownerAddress,
      tokenProgramId: tokenProgramId,
    );

    final payerAddress = payerPrivateKey.publicKey().toAddress();

    final createAssociatedTokenAccount = AssociatedTokenAccountProgram.associatedTokenAccount(
      payer: payerAddress,
      associatedToken: associatedTokenAccount.address,
      owner: ownerAddress,
      mint: mintAddress,
      tokenProgramId: tokenProgramId,
    );

    final blockhash = await _getLatestBlockhash(Commitment.confirmed);

    final transaction = SolanaTransaction(
      payerKey: payerAddress,
      instructions: [createAssociatedTokenAccount],
      recentBlockhash: blockhash,
      type: TransactionType.v0,
    );

    final serializedTransaction = await _signTransactionInternal(
      ownerPrivateKey: payerPrivateKey,
      transaction: transaction,
    );

    await sendTransaction(
      serializedTransaction: serializedTransaction,
      commitment: Commitment.confirmed,
    );

    // Wait for confirmation
    await Future.delayed(const Duration(seconds: 2));

    return associatedTokenAccount;
  }

  Future<PendingSolanaTransaction> _signSPLTokenTransaction({
    required int tokenDecimals,
    required String tokenMint,
    required Money inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required Commitment commitment,
    required Money solBalance,
  }) async {
    final mintAddress = SolAddress(tokenMint);
    final tokenProgramId = await _getTokenProgramId(mintAddress);

    ProgramDerivedAddress? associatedSenderAccount;
    SolAddress senderTokenProgramId = tokenProgramId;

    try {
      associatedSenderAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: mintAddress,
        owner: ownerPrivateKey.publicKey().toAddress(),
        tokenProgramId: tokenProgramId,
      );

      // Verify the account exists and get the actual program ID that owns it
      final accountInfo = await _provider!.request(
        SolanaRPCGetAccountInfo(
          account: associatedSenderAccount.address,
          commitment: Commitment.confirmed,
        ),
      );

      if (accountInfo != null) {
        senderTokenProgramId = accountInfo.owner;
      } else {
        associatedSenderAccount = null;
      }
    } catch (e) {
      associatedSenderAccount = null;
    }

    // If account doesn't exist with detected program ID, try standard token program as fallback
    if (associatedSenderAccount == null &&
        tokenProgramId.address != SPLTokenProgramConst.tokenProgramId.address) {
      try {
        associatedSenderAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
          mint: mintAddress,
          owner: ownerPrivateKey.publicKey().toAddress(),
          tokenProgramId: SPLTokenProgramConst.tokenProgramId,
        );

        final accountInfo = await _provider!.request(
          SolanaRPCGetAccountInfo(
            account: associatedSenderAccount.address,
            commitment: Commitment.confirmed,
          ),
        );

        if (accountInfo != null) {
          senderTokenProgramId = accountInfo.owner;
        } else {
          associatedSenderAccount = null;
        }
      } catch (_) {
        associatedSenderAccount = null;
      }
    }

    if (associatedSenderAccount == null) {
      throw SolanaNoAssociatedTokenAccountException(
        ownerPrivateKey.publicKey().toAddress().address,
        mintAddress.address,
      );
    }

    // Get or create recipient account using the sender's token program ID
    // This ensures both accounts use the same program
    ProgramDerivedAddress? associatedRecipientAccount;
    try {
      // First, try to get/create with the sender's actual program ID
      final recipientPDA = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: mintAddress,
        owner: SolAddress(destinationAddress),
        tokenProgramId: senderTokenProgramId,
      );

      // Check if account exists with correct program
      SolanaAccountInfo? recipientInfo;
      try {
        recipientInfo = await _provider!.request(
          SolanaRPCGetAccountInfo(
            account: recipientPDA.address,
            commitment: Commitment.confirmed,
          ),
        );
      } catch (_) {
        recipientInfo = null;
      }

      if (recipientInfo != null && recipientInfo.owner.address == senderTokenProgramId.address) {
        associatedRecipientAccount = recipientPDA;
      } else {
        // Create the account with the correct program ID
        final createATA = AssociatedTokenAccountProgram.associatedTokenAccount(
          payer: ownerPrivateKey.publicKey().toAddress(),
          associatedToken: recipientPDA.address,
          owner: SolAddress(destinationAddress),
          mint: mintAddress,
          tokenProgramId: senderTokenProgramId,
        );

        final blockhash = await _getLatestBlockhash(Commitment.confirmed);
        final createTransaction = SolanaTransaction(
          payerKey: ownerPrivateKey.publicKey().toAddress(),
          instructions: [createATA],
          recentBlockhash: blockhash,
          type: TransactionType.v0,
        );

        final serializedCreateTx = await _signTransactionInternal(
          ownerPrivateKey: ownerPrivateKey,
          transaction: createTransaction,
        );

        await sendTransaction(
          serializedTransaction: serializedCreateTx,
          commitment: Commitment.confirmed,
        );

        await Future.delayed(const Duration(seconds: 2));
        associatedRecipientAccount = recipientPDA;
      }
    } catch (e) {
      throw SolanaCreateAssociatedTokenAccountException(e.toString());
    }

    // Create transferChecked instruction with the correct token program ID
    final transferInstructions = _createTransferCheckedInstruction(
      tokenProgramId: senderTokenProgramId,
      source: associatedSenderAccount.address,
      destination: associatedRecipientAccount.address,
      mint: mintAddress,
      owner: ownerPrivateKey.publicKey().toAddress(),
      amount: inputAmount.amount,
      decimals: tokenDecimals,
    );

    final latestBlockHash = await _getLatestBlockhash(commitment);

    final transaction = SolanaTransaction(
      payerKey: ownerPrivateKey.publicKey().toAddress(),
      instructions: [transferInstructions],
      recentBlockhash: latestBlockHash,
    );

    final message = await _getMessageForSPLTokenTransaction(
      ownerAddress: ownerPrivateKey.publicKey().toAddress(),
      tokenDecimals: tokenDecimals,
      mintAddress: mintAddress,
      destinationAddress: associatedRecipientAccount.address,
      sourceAccount: associatedSenderAccount.address,
      amount: inputAmount,
      commitment: commitment,
      tokenProgramId: tokenProgramId,
    );

    final fee = await _getFeeFromCompiledMessage(message, commitment);

    final hasSufficientFundsLeft = await hasSufficientFundsLeftForRent(
      inputAmount: Money.zero(CryptoCurrency.sol),
      fee: fee,
      solBalance: solBalance,
    );

    if (!hasSufficientFundsLeft) throw SolanaSignSPLTokenTransactionRentException();

    final serializedTransaction = await _signTransactionInternal(
      ownerPrivateKey: ownerPrivateKey,
      transaction: transaction,
    );

    sendTx() => sendTransaction(
          serializedTransaction: serializedTransaction,
          commitment: commitment,
        );

    return PendingSolanaTransaction(
      amount: inputAmount,
      serializedTransaction: serializedTransaction,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );
  }

  Future<String> _signTransactionInternal({
    required SolanaPrivateKey ownerPrivateKey,
    required SolanaTransaction transaction,
  }) async {
    final ownerSignature = ownerPrivateKey.sign(transaction.serializeMessage());

    transaction.addSignature(ownerPrivateKey.publicKey().toAddress(), ownerSignature);

    return transaction.serializeString();
  }

  Future<String> sendTransaction(
          {required String serializedTransaction, required Commitment commitment}) =>
      _provider!.request(
        SolanaRPCSendTransaction(
          encodedTransaction: serializedTransaction,
          commitment: commitment,
        ),
      );

  Future<String?> getIconImageFromTokenUri(String uri) async {
    if (uri.isEmpty || uri == '…') return null;

    try {
      final client = ProxyWrapper().getHttpIOClient();
      final response = await client.get(Uri.parse(uri));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse['image'];
      } else {
        return null;
      }
    } catch (e) {
      printV('Error occurred while fetching token image: \n${e.toString()}');
      return null;
    }
  }

  Future<List<MoralisSolanaTokenBalance>> fetchWalletTokensFromMoralis(
    String address,
  ) async {
    try {
      if (secrets.moralisApiKey.isEmpty) {
        printV('Moralis API key is empty, cannot fetch wallet tokens');
        return [];
      }

      final uri = Uri.https(
        'solana-gateway.moralis.io',
        '/account/mainnet/$address/tokens',
      );

      final response = await client.get(
        uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        printV(
          'Moralis Solana API returned status: '
          '${response.statusCode}',
        );
        return [];
      }

      final decodedResponse = jsonDecode(response.body) as List;

      final List<MoralisSolanaTokenBalance> tokens = [];

      for (final item in decodedResponse) {
        final tokenData = item as Map<String, dynamic>;

        final amountStr = tokenData['amount'] as String? ?? '0';
        final amount = double.tryParse(amountStr) ?? 0.0;

        if (amount <= 0) continue;

        final mint = tokenData['mint'] as String? ?? '';
        if (mint.isEmpty) continue;

        final amountRaw = tokenData['amountRaw'] as String? ?? '0';

        final decimals = tokenData['decimals'] as int? ?? 0;

        final associatedTokenAddress = tokenData['associatedTokenAddress'] as String? ?? '';

        tokens.add(
          MoralisSolanaTokenBalance(
            mint: mint,
            amount: amount,
            amountRaw: amountRaw,
            decimals: decimals,
            associatedTokenAddress: associatedTokenAddress,
          ),
        );
      }

      return tokens;
    } catch (e) {
      printV('Error fetching wallet tokens from Moralis: ${e.toString()}');
      return [];
    }
  }

  Future<bool?> isTokenVerifiedOnJupiter(String mintAddress) async {
    if (_jupiterVerificationCache.containsKey(mintAddress)) {
      return _jupiterVerificationCache[mintAddress];
    }

    try {
      final uri = Uri.https(
        "lite-api.jup.ag",
        "/tokens/v2/search",
        {"query": mintAddress},
      );

      final response = await client.get(
        uri,
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        printV("Jupiter token API returned status: ${response.statusCode}");
        return null;
      }

      final decodedResponse = jsonDecode(response.body) as List;

      for (final item in decodedResponse) {
        final tokenData = item as Map<String, dynamic>;

        if (tokenData["id"] == mintAddress) {
          final isVerified = tokenData["isVerified"] as bool? ?? false;
          _jupiterVerificationCache[mintAddress] = isVerified;
          return isVerified;
        }
      }

      // this means Jupiter doesn't index this mint at all, so we can't say either
      return null;
    } catch (e) {
      printV("Error checking Jupiter verification: ${e.toString()}");
      return null;
    }
  }
}

class MoralisSolanaTokenBalance {
  final String mint;
  final double amount;
  final String amountRaw;
  final int decimals;
  final String associatedTokenAddress;

  const MoralisSolanaTokenBalance({
    required this.mint,
    required this.amount,
    required this.amountRaw,
    required this.decimals,
    required this.associatedTokenAddress,
  });
}
