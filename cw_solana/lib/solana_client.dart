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

  Future<SolanaTransactionModel?> parseTransaction({
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
            return transactionModel;
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
            return transactionModel;
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
          return null;
        }
      }
    } catch (e, s) {
      printV("Error parsing transaction: $e\n$s");
    }

    return null;
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

    for (int i = 0; i < meta.preBalances.length; i++) {
      final preBalance = meta.preBalances[i];
      final postBalance = meta.postBalances[i];
      final balanceChange = preBalance - postBalance;

      if (balanceChange > BigInt.zero) {
        // This account sent funds
        sender = message.accountKeys[i].address;
        totalBalanceChange += balanceChange;
      } else if (balanceChange < BigInt.zero) {
        // This account received funds
        receiver = message.accountKeys[i].address;
      }
    }

    // We subtract the fee from total balance change if the fee payer is the sender
    if (sender == message.accountKeys[feePayerIndex].address) {
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
                maxSupportedTransactionVersion: 0,
              ),
            );
          } catch (e) {
            // printV("Error fetching transaction: $e");
            return null;
          }
        }));

        final versionedBatchResponses = batchResponses.whereType<VersionedTransactionResponse>();

        final parsedTransactionsFutures = versionedBatchResponses.map((tx) => parseTransaction(
              txResponse: tx,
              splTokenSymbol: splTokenSymbol,
              walletAddress: walletAddress?.address ?? address.address,
            ));

        final parsedTransactions = await Future.wait(parsedTransactionsFutures);

        transactions.addAll(parsedTransactions.whereType<SolanaTransactionModel>().toList());

        // Only update UI if we have new valid transactions
        if (parsedTransactions.isNotEmpty) {
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
