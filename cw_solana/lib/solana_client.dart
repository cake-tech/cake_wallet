import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/crypto_currency.dart';
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

class SolanaWalletClient {
  // Minimum amount in SOL to consider a transaction valid (to filter spam)
  static const double minValidAmount = 0.00000003;
  final httpClient = ProxyWrapper().getHttpClient();
  late final client = ProxyWrapper().getHttpIOClient();
  SolanaRPC? _provider;

  bool connect(Node node) {
    try {
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

  Future<double> getBalance(String walletAddress, {bool throwOnError = false}) async {
    try {
      final balance = await _provider!.requestWithContext(
        SolanaRPCGetBalance(
          account: SolAddress(walletAddress),
        ),
      );

      final balInLamp = balance.result.toDouble();

      final solBalance = balInLamp / SolanaUtils.lamportsPerSol;

      return solBalance;
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return 0.0;
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

  Future<SolanaBalance?> getSplTokenBalance(String mintAddress, String walletAddress,
      {bool throwOnError = false}) async {
    try {
      // Fetch the token accounts (a token can have multiple accounts for various uses)
      final tokenAccounts = await getSPLTokenAccounts(mintAddress, walletAddress);

      // Handle scenario where there is no token account
      if (tokenAccounts == null || tokenAccounts.isEmpty) {
        return null;
      }

      // Sum the balances of all accounts with the specified mint address
      double totalBalance = 0.0;

      for (var tokenAccount in tokenAccounts) {
        final tokenAmountResult = await _provider!.request(
          SolanaRPCGetTokenAccountBalance(account: tokenAccount.pubkey),
        );

        final balance = tokenAmountResult.uiAmountString;

        final balanceAsDouble = double.tryParse(balance ?? '0.0') ?? 0.0;

        totalBalance += balanceAsDouble;
      }

      return SolanaBalance(totalBalance);
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  Future<double> getFeeForMessage(String message, Commitment commitment) async {
    try {
      final feeForMessage = await _provider!.request(
        SolanaRPCGetFeeForMessage(
          encodedMessage: message,
          commitment: commitment,
        ),
      );

      final fee = (feeForMessage?.toDouble() ?? 0.0) / SolanaUtils.lamportsPerSol;
      return fee;
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> getEstimatedFee(SolanaPublicKey publicKey, Commitment commitment) async {
    final message = await _getMessageForNativeTransaction(
      publicKey: publicKey,
      destinationAddress: publicKey.toAddress().address,
      lamports: SolanaUtils.lamportsPerSol,
      commitment: commitment,
    );

    final estimatedFee = await _getFeeFromCompiledMessage(
      message,
      commitment,
    );
    return estimatedFee;
  }

  Future<List<SolanaTransactionModel>?> parseTransaction({
    VersionedTransactionResponse? txResponse,
    required String walletAddress,
    String? splTokenSymbol,
  }) async {
    if (txResponse == null) return null;

    try {
      final blockTime = txResponse.blockTime;
      final meta = txResponse.meta;
      final transaction = txResponse.transaction;

      if (meta == null || transaction == null) return null;

      final int fee = meta.fee;
      final feeInSol = fee / SolanaUtils.lamportsPerSol;

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
          feeInSol: feeInSol,
          walletAddress: walletAddress,
          signature: signature,
          blockTime: blockTime,
          instructions: instructions,
          splTokenSymbol: splTokenSymbol,
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
            feeInSol: feeInSol,
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
            feeInSol: feeInSol,
            instruction: instruction,
            walletAddress: walletAddress,
            signature: signature,
            blockTime: blockTime,
            splTokenSymbol: splTokenSymbol,
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

  /// Detects if a transaction is a swap by checking for both native SOL
  /// and SPL token balance changes involving the wallet address
  bool _isSwapTransaction(
    ConfirmedTransactionMeta meta,
    VersionedMessage message,
    String walletAddress,
  ) {
    bool hasNativeBalanceChange = false;
    bool hasTokenBalanceChange = false;

    // First we check if there are any native SOL balance changes for the wallet
    final preBalances = meta.preBalances;
    final postBalances = meta.postBalances;
    final accountKeys = message.accountKeys;

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

          if (balanceChange != BigInt.zero) {
            hasNativeBalanceChange = true;
            break;
          }
        }
      }
    }

    // Next, we check if there are any SPL token balance changes

    // There is a caveat though, Jupiter swaps token accounts might be intermediate accounts, so we need to check for that, otherwise we might miss some transactions
    final preTokenBalances = meta.preTokenBalances;
    final postTokenBalances = meta.postTokenBalances;

    if (preTokenBalances != null && postTokenBalances != null) {
      bool hasTokenDecrease = false;
      bool hasTokenIncrease = false;

      for (final preTokenBal in preTokenBalances) {
        final mint = preTokenBal.mint.address;
        final preAmount = preTokenBal.uiTokenAmount.uiAmount ?? 0.0;

        // We find the corresponding post balance by matching mint and owner
        for (final postTokenBal in postTokenBalances) {
          final postMint = postTokenBal.mint.address;
          final postOwner = postTokenBal.owner?.address ?? '';
          final preOwner = preTokenBal.owner?.address ?? '';
          final postAmount = postTokenBal.uiTokenAmount.uiAmount ?? 0.0;

          if (postMint == mint && postOwner == preOwner) {
            final diff = postAmount - preAmount;
            if (diff < 0) {
              hasTokenDecrease = true;
            } else if (diff > 0) {
              hasTokenIncrease = true;
            }
            break;
          }
        }
      }

      // If we have both token decreases and increases, or if wallet sent SOL and there are token changes, it's likely a swap
      if (hasNativeBalanceChange && (hasTokenDecrease || hasTokenIncrease)) {
        hasTokenBalanceChange = true;
      }
    }

    // It's a swap if both native and token balances changed
    return hasNativeBalanceChange && hasTokenBalanceChange;
  }

  /// Parses a swap transaction and creates dual entries (outgoing and incoming)
  Future<List<SolanaTransactionModel>> _parseSwapTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required double feeInSol,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
    required List<CompiledInstruction> instructions,
    String? splTokenSymbol,
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

    final bool isSplToSplSwap =
        decreasedMintForWallet != null &&
        increasedMintForWallet != null &&
        decreasedMintForWallet != increasedMintForWallet;

    // Parse outgoing side (what was sent)
    double outgoingAmount = 0.0;
    String outgoingTokenSymbol = '';
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
            outgoingTokenSymbol = 'SOL';
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
                outgoingTokenSymbol = token?.symbol ?? 'TOKEN';
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
    String incomingTokenSymbol = '';
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
            incomingTokenSymbol = 'SOL';
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
              incomingTokenSymbol = token?.symbol ?? 'TOKEN';
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
        amount: outgoingAmount,
        programId: outgoingMintAddress == null
            ? SystemProgramConst.programId.address
            : SPLTokenProgramConst.tokenProgramId.address,
        blockTimeInInt: blockTime?.toInt() ?? 0,
        tokenSymbol: outgoingTokenSymbol,
        fee: feeInSol,
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
        amount: incomingAmount,
        programId: incomingMintAddress == null
            ? SystemProgramConst.programId.address
            : SPLTokenProgramConst.tokenProgramId.address,
        blockTimeInInt: blockTime?.toInt() ?? 0,
        tokenSymbol: incomingTokenSymbol,
        fee: 0.0, // Fee only charged on outgoing side
      ));
    }

    return swapTransactions;
  }

  Future<SolanaTransactionModel?> _parseNativeTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required double feeInSol,
    required int feePayerIndex,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
  }) async {
    // Calculate total balance changes across all accounts
    BigInt totalBalanceChange = BigInt.zero;
    String? sender;
    String? receiver;

    final accountKeysLength = message.accountKeys.length;
    final balancesLength = meta.preBalances.length;
    final maxLength = accountKeysLength < balancesLength ? accountKeysLength : balancesLength;

    for (int i = 0; i < maxLength; i++) {
      final preBalance = meta.preBalances[i];
      final postBalance = meta.postBalances[i];
      final balanceChange = preBalance - postBalance;

      if (balanceChange > BigInt.zero) {
        // This account sent funds
        if (i < accountKeysLength) {
          sender = message.accountKeys[i].address;
          totalBalanceChange += balanceChange;
        }
      } else if (balanceChange < BigInt.zero) {
        // This account received funds
        if (i < accountKeysLength) {
          receiver = message.accountKeys[i].address;
        }
      }
    }

    // We subtract the fee from total balance change if the fee payer is the sender
    if (sender != null &&
        feePayerIndex < message.accountKeys.length &&
        sender == message.accountKeys[feePayerIndex].address) {
      totalBalanceChange -= BigInt.from(fee);
    }

    if (sender == null || receiver == null) {
      return null;
    }

    final amount = totalBalanceChange / BigInt.from(1e9);
    final amountInSol = amount.abs().toDouble();

    // Skip transactions with very small amounts (likely spam)
    if (amountInSol < minValidAmount) {
      return null;
    }

    return SolanaTransactionModel(
      isOutgoingTx: sender == walletAddress,
      from: sender,
      to: receiver,
      id: signature,
      amount: amountInSol,
      programId: SystemProgramConst.programId.address,
      tokenSymbol: 'SOL',
      blockTimeInInt: blockTime?.toInt() ?? 0,
      fee: feeInSol,
    );
  }

  Future<SolanaTransactionModel?> _parseSPLTokenTransaction({
    required VersionedMessage message,
    required ConfirmedTransactionMeta meta,
    required int fee,
    required double feeInSol,
    required CompiledInstruction instruction,
    required String walletAddress,
    required String signature,
    required BigInt? blockTime,
    String? splTokenSymbol,
  }) async {
    final preBalances = meta.preTokenBalances;
    final postBalances = meta.postTokenBalances;

    double amount = 0.0;
    bool isOutgoing = false;
    String? mintAddress;

    double userPreAmount = 0.0;
    if (preBalances != null && preBalances.isNotEmpty) {
      for (final preBal in preBalances) {
        if (preBal.owner?.address == walletAddress) {
          userPreAmount = preBal.uiTokenAmount.uiAmount ?? 0.0;

          mintAddress = preBal.mint.address;
          break;
        }
      }
    }

    double userPostAmount = 0.0;
    if (postBalances != null && postBalances.isNotEmpty) {
      for (final postBal in postBalances) {
        if (postBal.owner?.address == walletAddress) {
          userPostAmount = postBal.uiTokenAmount.uiAmount ?? 0.0;

          mintAddress ??= postBal.mint.address;
          break;
        }
      }
    }

    final diff = userPreAmount - userPostAmount;
    final rawAmount = diff.abs();

    final amountInString = rawAmount.toStringAsFixed(6);
    amount = double.parse(amountInString);

    isOutgoing = diff > 0;

    if (mintAddress == null && instruction.accounts.length >= 4) {
      final mintIndex = instruction.accounts[3];
      mintAddress = message.accountKeys[mintIndex].address;
    }

    final sender = message.accountKeys[instruction.accounts[0]].address;
    final receiver = message.accountKeys[instruction.accounts[1]].address;

    String? tokenSymbol = splTokenSymbol;

    if (tokenSymbol == null && mintAddress != null) {
      final token = await getTokenInfo(mintAddress);
      tokenSymbol = token?.symbol;
    }

    return SolanaTransactionModel(
      isOutgoingTx: isOutgoing,
      from: sender,
      to: receiver,
      id: signature,
      amount: amount,
      programId: SPLTokenProgramConst.tokenProgramId.address,
      blockTimeInInt: blockTime?.toInt() ?? 0,
      tokenSymbol: tokenSymbol ?? '',
      fee: feeInSol,
    );
  }

  /// Fetches a specific transaction by signature and parses it
  /// It returns a TransactionFetchResult object containing both transactions and token mints extracted from the transaction or null if the transaction is not found or cannot be parsed
  Future<TransactionFetchResult?> fetchTransactionBySignature({
    required String signature,
    required String walletAddress,
    String? splTokenSymbol,
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
        splTokenSymbol: splTokenSymbol,
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

  /// Load the Address's transactions into the account
  Future<List<SolanaTransactionModel>> fetchTransactions(
    SolAddress address, {
    String? splTokenSymbol,
    int? splTokenDecimal,
    Commitment? commitment,
    SolAddress? walletAddress,
    required void Function(List<SolanaTransactionModel>) onUpdate,
  }) async {
    List<SolanaTransactionModel> transactions = [];
    try {
      final signatures = await _provider!.request(
        SolanaRPCGetSignaturesForAddress(
          account: address,
          commitment: commitment,
        ),
      );

      // The maximum concurrent batch size.
      const int batchSize = 10;

      for (int i = 0; i < signatures.length; i += batchSize) {
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
            return null;
          }
        }));

        final versionedBatchResponses = batchResponses.whereType<VersionedTransactionResponse>();

        final parsedTransactionsFutures = versionedBatchResponses.map((tx) => parseTransaction(
              txResponse: tx,
              splTokenSymbol: splTokenSymbol,
              walletAddress: walletAddress?.address ?? address.address,
            ));

        final parsedTransactionsLists = await Future.wait(parsedTransactionsFutures);

        // We flatten the list of lists into a single list
        for (final parsedList in parsedTransactionsLists) {
          if (parsedList != null) {
            transactions.addAll(parsedList);
          }
        }

        // Only update UI if we have new valid transactions
        if (transactions.isNotEmpty) {
          onUpdate(List<SolanaTransactionModel>.from(transactions));
        }

        if (i + batchSize < signatures.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return transactions;
    } catch (err, s) {
      printV('Error fetching transactions: $err \n$s');
      return [];
    }
  }

  Future<List<SolanaTransactionModel>> getSPLTokenTransfers({
    required String mintAddress,
    required String splTokenSymbol,
    required int splTokenDecimal,
    required SolanaPrivateKey privateKey,
    required void Function(List<SolanaTransactionModel>) onUpdate,
  }) async {
    ProgramDerivedAddress? associatedTokenAccount;
    final ownerWalletAddress = privateKey.publicKey().toAddress();
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

    if (associatedTokenAccount == null) return [];

    final accountPublicKey = associatedTokenAccount.address;

    final tokenTransactions = await fetchTransactions(
      accountPublicKey,
      splTokenSymbol: splTokenSymbol,
      splTokenDecimal: splTokenDecimal,
      walletAddress: ownerWalletAddress,
      onUpdate: onUpdate,
    );

    return tokenTransactions;
  }

  final Map<String, SPLToken?> tokenInfoCache = {};

  Future<SPLToken?> getTokenInfo(String mintAddress) async {
    if (tokenInfoCache.containsKey(mintAddress)) {
      return tokenInfoCache[mintAddress];
    } else {
      final token = await fetchSPLTokenInfo(mintAddress);
      if (token != null) {
        tokenInfoCache[mintAddress] = token;
      }
      return token;
    }
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

      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      final symbol = (decodedResponse['symbol'] ?? '') as String;

      final name = decodedResponse['name'] ?? '';
      final decimal = decodedResponse['decimals'] ?? '0';
      final iconPath = decodedResponse['logo'] ?? '';

      String filteredTokenSymbol =
          symbol.replaceFirst(RegExp('^\\\$'), '').replaceAll('\u0000', '');

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

  void stop() {}

  SolanaRPC? get getSolanaProvider => _provider;

  Future<PendingSolanaTransaction> signSolanaTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required double inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required bool isSendAll,
    required double solBalance,
    String? tokenMint,
    List<String> references = const [],
  }) async {
    const commitment = Commitment.confirmed;

    if (tokenTitle == CryptoCurrency.sol.title) {
      final pendingNativeTokenTransaction = await _signNativeTokenTransaction(
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerPrivateKey: ownerPrivateKey,
        commitment: commitment,
        isSendAll: isSendAll,
        solBalance: solBalance,
      );
      return pendingNativeTokenTransaction;
    } else {
      final pendingSPLTokenTransaction = _signSPLTokenTransaction(
        tokenDecimals: tokenDecimals,
        tokenMint: tokenMint!,
        inputAmount: inputAmount,
        ownerPrivateKey: ownerPrivateKey,
        destinationAddress: destinationAddress,
        commitment: commitment,
        solBalance: solBalance,
      );
      return pendingSPLTokenTransaction;
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
    required int lamports,
    required Commitment commitment,
  }) async {
    final instructions = [
      SystemProgram.transfer(
        from: publicKey.toAddress(),
        layout: SystemTransferLayout(lamports: BigInt.from(lamports)),
        to: SolAddress(destinationAddress),
      ),
    ];

    final latestBlockhash = await _getLatestBlockhash(commitment);

    final message = Message.compile(
      transactionInstructions: instructions,
      payer: publicKey.toAddress(),
      recentBlockhash: latestBlockhash,
    );
    return message;
  }

  Future<Message> _getMessageForSPLTokenTransaction({
    required SolAddress ownerAddress,
    required SolAddress destinationAddress,
    required int tokenDecimals,
    required SolAddress mintAddress,
    required SolAddress sourceAccount,
    required int amount,
    required Commitment commitment,
  }) async {
    final instructions = [
      SPLTokenProgram.transferChecked(
        layout: SPLTokenTransferCheckedLayout(
          amount: BigInt.from(amount),
          decimals: tokenDecimals,
        ),
        mint: mintAddress,
        source: sourceAccount,
        destination: destinationAddress,
        owner: ownerAddress,
      )
    ];

    final latestBlockhash = await _getLatestBlockhash(commitment);

    final message = Message.compile(
      transactionInstructions: instructions,
      payer: ownerAddress,
      recentBlockhash: latestBlockhash,
    );
    return message;
  }

  Future<double> _getFeeFromCompiledMessage(Message message, Commitment commitment) async {
    final base64Message = base64Encode(message.serialize());

    final fee = await getFeeForMessage(base64Message, commitment);

    return fee;
  }

  Future<bool> hasSufficientFundsLeftForRent({
    required double inputAmount,
    required double solBalance,
    required double fee,
  }) async {
    final rent = await _provider!.request(
      SolanaRPCGetMinimumBalanceForRentExemption(
        size: SolanaTokenAccountUtils.accountSize,
      ),
    );

    final rentInSol = (rent.toDouble() / SolanaUtils.lamportsPerSol).toDouble();

    final remnant = solBalance - (inputAmount + fee);

    if (remnant > rentInSol) return true;

    return false;
  }

  Future<PendingSolanaTransaction> _signNativeTokenTransaction({
    required double inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required Commitment commitment,
    required bool isSendAll,
    required double solBalance,
  }) async {
    // Convert SOL to lamport
    int lamports = (inputAmount * SolanaUtils.lamportsPerSol).toInt();

    Message message = await _getMessageForNativeTransaction(
      publicKey: ownerPrivateKey.publicKey(),
      destinationAddress: destinationAddress,
      lamports: lamports,
      commitment: commitment,
    );

    SolAddress latestBlockhash = await _getLatestBlockhash(commitment);

    final fee = await _getFeeFromCompiledMessage(
      message,
      commitment,
    );

    bool hasSufficientFundsLeft = await hasSufficientFundsLeftForRent(
      inputAmount: inputAmount,
      fee: fee,
      solBalance: solBalance,
    );

    if (!hasSufficientFundsLeft) {
      throw SolanaSignNativeTokenTransactionRentException();
    }

    String serializedTransaction;
    if (isSendAll) {
      final feeInLamports = (fee * SolanaUtils.lamportsPerSol).toInt();
      final updatedLamports = lamports - feeInLamports;

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
        lamports: lamports,
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

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      serializedTransaction: serializedTransaction,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );

    return pendingTransaction;
  }

  SolanaTransaction _constructNativeTransaction({
    required SolanaPrivateKey ownerPrivateKey,
    required String destinationAddress,
    required SolAddress latestBlockhash,
    required int lamports,
  }) {
    final owner = ownerPrivateKey.publicKey().toAddress();

    /// Create a transfer instruction to move funds from the owner to the receiver.
    final transferInstruction = SystemProgram.transfer(
      from: owner,
      layout: SystemTransferLayout(lamports: BigInt.from(lamports)),
      to: SolAddress(destinationAddress),
    );

    /// Construct a Solana transaction with the transfer instruction.
    return SolanaTransaction(
      instructions: [transferInstruction],
      recentBlockhash: latestBlockhash,
      payerKey: ownerPrivateKey.publicKey().toAddress(),
      type: TransactionType.v0,
    );
  }

  Future<ProgramDerivedAddress?> _getOrCreateAssociatedTokenAccount({
    required SolanaPrivateKey payerPrivateKey,
    required SolAddress ownerAddress,
    required SolAddress mintAddress,
    required bool shouldCreateATA,
  }) async {
    final associatedTokenAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
      mint: mintAddress,
      owner: ownerAddress,
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

    // If account exists, we return the associated token account
    if (accountInfo != null) return associatedTokenAccount;

    if (!shouldCreateATA) return null;

    final payerAddress = payerPrivateKey.publicKey().toAddress();

    final createAssociatedTokenAccount = AssociatedTokenAccountProgram.associatedTokenAccount(
      payer: payerAddress,
      associatedToken: associatedTokenAccount.address,
      owner: ownerAddress,
      mint: mintAddress,
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
    required double inputAmount,
    required String destinationAddress,
    required SolanaPrivateKey ownerPrivateKey,
    required Commitment commitment,
    required double solBalance,
  }) async {
    final mintAddress = SolAddress(tokenMint);

    // Input by the user
    final amount = (inputAmount * math.pow(10, tokenDecimals)).toInt();
    ProgramDerivedAddress? associatedSenderAccount;
    try {
      associatedSenderAccount = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: mintAddress,
        owner: ownerPrivateKey.publicKey().toAddress(),
      );
    } catch (e) {
      associatedSenderAccount = null;
    }

    // Throw an appropriate exception if the sender has no associated
    // token account
    if (associatedSenderAccount == null) {
      throw SolanaNoAssociatedTokenAccountException(
        ownerPrivateKey.publicKey().toAddress().address,
        mintAddress.address,
      );
    }

    ProgramDerivedAddress? associatedRecipientAccount;
    try {
      associatedRecipientAccount = await _getOrCreateAssociatedTokenAccount(
        payerPrivateKey: ownerPrivateKey,
        mintAddress: mintAddress,
        ownerAddress: SolAddress(destinationAddress),
        shouldCreateATA: true,
      );
    } catch (e) {
      associatedRecipientAccount = null;

      throw SolanaCreateAssociatedTokenAccountException(e.toString());
    }

    if (associatedRecipientAccount == null) {
      throw SolanaCreateAssociatedTokenAccountException(
        'Error fetching recipient associated token account',
      );
    }

    final transferInstructions = SPLTokenProgram.transferChecked(
      layout: SPLTokenTransferCheckedLayout(
        amount: BigInt.from(amount),
        decimals: tokenDecimals,
      ),
      mint: mintAddress,
      source: associatedSenderAccount.address,
      destination: associatedRecipientAccount.address,
      owner: ownerPrivateKey.publicKey().toAddress(),
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
      amount: amount,
      commitment: commitment,
    );

    final fee = await _getFeeFromCompiledMessage(message, commitment);

    bool hasSufficientFundsLeft = await hasSufficientFundsLeftForRent(
      inputAmount: 0,
      fee: fee,
      solBalance: solBalance,
    );

    if (!hasSufficientFundsLeft) {
      throw SolanaSignSPLTokenTransactionRentException();
    }

    final serializedTransaction = await _signTransactionInternal(
      ownerPrivateKey: ownerPrivateKey,
      transaction: transaction,
    );

    sendTx() async => await sendTransaction(
          serializedTransaction: serializedTransaction,
          commitment: commitment,
        );

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      serializedTransaction: serializedTransaction,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );
    return pendingTransaction;
  }

  Future<String> _signTransactionInternal({
    required SolanaPrivateKey ownerPrivateKey,
    required SolanaTransaction transaction,
  }) async {
    /// Sign the transaction with the owner's private key.
    final ownerSignature = ownerPrivateKey.sign(transaction.serializeMessage());

    transaction.addSignature(ownerPrivateKey.publicKey().toAddress(), ownerSignature);

    /// Serialize the transaction.
    final serializedTransaction = transaction.serializeString();

    return serializedTransaction;
  }

  Future<String> sendTransaction({
    required String serializedTransaction,
    required Commitment commitment,
  }) async {
    try {
      /// Send the transaction to the Solana network.
      final signature = await _provider!.request(
        SolanaRPCSendTransaction(
          encodedTransaction: serializedTransaction,
          commitment: commitment,
        ),
      );
      return signature;
    } catch (e) {
      throw Exception(e);
    }
  }

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
}
