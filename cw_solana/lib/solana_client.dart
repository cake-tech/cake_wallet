import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import '.secrets.g.dart' as secrets;

class SolanaWalletClient {
  final httpClient = http.Client();
  SolanaClient? _client;

  bool connect(Node node) {
    try {
      Uri? rpcUri;
      String webSocketUrl;
      bool isModifiedNodeUri = false;

      if (node.uriRaw == 'rpc.ankr.com') {
        isModifiedNodeUri = true;
        String ankrApiKey = secrets.ankrApiKey;

        rpcUri = Uri.https(node.uriRaw, '/solana/$ankrApiKey');
        webSocketUrl = 'wss://${node.uriRaw}/solana/ws/$ankrApiKey';
      } else {
        webSocketUrl = 'wss://${node.uriRaw}';
      }

      _client = SolanaClient(
        rpcUrl: isModifiedNodeUri ? rpcUri! : node.uri,
        websocketUrl: Uri.parse(webSocketUrl),
        timeout: const Duration(minutes: 2),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<double> getBalance(String address) async {
    try {
      final balance = await _client!.rpcClient.getBalance(address);

      final solBalance = balance.value / lamportsPerSol;

      return solBalance;
    } catch (_) {
      return 0.0;
    }
  }

  Future<ProgramAccountsResult?> getSPLTokenAccounts(String mintAddress, String publicKey) async {
    try {
      final tokenAccounts = await _client!.rpcClient.getTokenAccountsByOwner(
        publicKey,
        TokenAccountsFilter.byMint(mintAddress),
        commitment: Commitment.confirmed,
        encoding: Encoding.jsonParsed,
      );
      return tokenAccounts;
    } catch (e) {
      return null;
    }
  }

  Future<SolanaBalance?> getSplTokenBalance(String mintAddress, String publicKey) async {
    // Fetch the token accounts (a token can have multiple accounts for various uses)
    final tokenAccounts = await getSPLTokenAccounts(mintAddress, publicKey);

    // Handle scenario where there is no token account
    if (tokenAccounts == null || tokenAccounts.value.isEmpty) {
      return null;
    }

    // Sum the balances of all accounts with the specified mint address
    double totalBalance = 0.0;

    for (var programAccount in tokenAccounts.value) {
      final tokenAmountResult =
          await _client!.rpcClient.getTokenAccountBalance(programAccount.pubkey);

      final balance = tokenAmountResult.value.uiAmountString;

      final balanceAsDouble = double.tryParse(balance ?? '0.0') ?? 0.0;

      totalBalance += balanceAsDouble;
    }

    return SolanaBalance(totalBalance);
  }

  Future<double> getFeeForMessage(String message, Commitment commitment) async {
    try {
      final feeForMessage =
          await _client!.rpcClient.getFeeForMessage(message, commitment: commitment);
      final fee = (feeForMessage ?? 0.0) / lamportsPerSol;
      return fee;
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> getEstimatedFee(Ed25519HDKeyPair ownerKeypair) async {
    const commitment = Commitment.confirmed;

    final message =
        _getMessageForNativeTransaction(ownerKeypair, ownerKeypair.address, lamportsPerSol);

    final recentBlockhash = await _getRecentBlockhash(commitment);

    final estimatedFee =
        _getFeeFromCompiledMessage(message, ownerKeypair.publicKey, recentBlockhash, commitment);
    return estimatedFee;
  }

  /// Load the Address's transactions into the account
  Future<List<SolanaTransactionModel>> fetchTransactions(
    Ed25519HDPublicKey publicKey, {
    String? splTokenSymbol,
    int? splTokenDecimal,
  }) async {
    List<SolanaTransactionModel> transactions = [];

    try {
      final response = await _client!.rpcClient.getTransactionsList(
        publicKey,
        commitment: Commitment.confirmed,
        limit: 1000,
      );

      for (final tx in response) {
        if (tx.transaction is ParsedTransaction) {
          final parsedTx = (tx.transaction as ParsedTransaction);
          final message = parsedTx.message;

          final fee = (tx.meta?.fee ?? 0) / lamportsPerSol;

          for (final instruction in message.instructions) {
            if (instruction is ParsedInstruction) {
              instruction.map(
                system: (systemData) {
                  systemData.parsed.map(
                    transfer: (transferData) {
                      ParsedSystemTransferInformation transfer = transferData.info;
                      bool isOutgoingTx = transfer.source == publicKey.toBase58();

                      double amount = transfer.lamports.toDouble() / lamportsPerSol;

                      transactions.add(
                        SolanaTransactionModel(
                          id: parsedTx.signatures.first,
                          from: transfer.source,
                          to: transfer.destination,
                          amount: amount,
                          isOutgoingTx: isOutgoingTx,
                          blockTimeInInt: tx.blockTime!,
                          fee: fee,
                          programId: SystemProgram.programId,
                          tokenSymbol: 'SOL',
                        ),
                      );
                    },
                    transferChecked: (_) {},
                    unsupported: (_) {},
                  );
                },
                splToken: (splTokenData) {
                  if (splTokenSymbol != null) {
                    splTokenData.parsed.map(
                      transfer: (transferData) {
                        SplTokenTransferInfo transfer = transferData.info;
                        bool isOutgoingTx = transfer.source == publicKey.toBase58();

                        double amount = (double.tryParse(transfer.amount) ?? 0.0) /
                            pow(10, splTokenDecimal ?? 9);

                        transactions.add(
                          SolanaTransactionModel(
                            id: parsedTx.signatures.first,
                            fee: fee,
                            from: transfer.source,
                            to: transfer.destination,
                            amount: amount,
                            isOutgoingTx: isOutgoingTx,
                            programId: TokenProgram.programId,
                            blockTimeInInt: tx.blockTime!,
                            tokenSymbol: splTokenSymbol,
                          ),
                        );
                      },
                      transferChecked: (transferCheckedData) {
                        SplTokenTransferCheckedInfo transfer = transferCheckedData.info;
                        bool isOutgoingTx = transfer.source == publicKey.toBase58();
                        double amount =
                            double.tryParse(transfer.tokenAmount.uiAmountString ?? '0.0') ?? 0.0;

                        transactions.add(
                          SolanaTransactionModel(
                            id: parsedTx.signatures.first,
                            fee: fee,
                            from: transfer.source,
                            to: transfer.destination,
                            amount: amount,
                            isOutgoingTx: isOutgoingTx,
                            programId: TokenProgram.programId,
                            blockTimeInInt: tx.blockTime!,
                            tokenSymbol: splTokenSymbol,
                          ),
                        );
                      },
                      generic: (genericData) {},
                    );
                  }
                },
                memo: (_) {},
                unsupported: (a) {},
              );
            }
          }
        }
      }

      return transactions;
    } catch (err) {
      return [];
    }
  }

  Future<List<SolanaTransactionModel>> getSPLTokenTransfers(
    String address,
    String splTokenSymbol,
    int splTokenDecimal,
    Ed25519HDKeyPair ownerKeypair,
  ) async {
    final tokenMint = Ed25519HDPublicKey.fromBase58(address);

    ProgramAccount? associatedTokenAccount;

    try {
      associatedTokenAccount = await _client!.getAssociatedTokenAccount(
        mint: tokenMint,
        owner: ownerKeypair.publicKey,
        commitment: Commitment.confirmed,
      );
    } catch (_) {}

    if (associatedTokenAccount == null) return [];

    final accountPublicKey = Ed25519HDPublicKey.fromBase58(associatedTokenAccount.pubkey);

    final tokenTransactions = await fetchTransactions(
      accountPublicKey,
      splTokenSymbol: splTokenSymbol,
      splTokenDecimal: splTokenDecimal,
    );

    return tokenTransactions;
  }

  void stop() {}

  SolanaClient? get getSolanaClient => _client;

  Future<PendingSolanaTransaction> signSolanaTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    required bool isSendAll,
    String? tokenMint,
    List<String> references = const [],
  }) async {
    const commitment = Commitment.confirmed;

    if (tokenTitle == CryptoCurrency.sol.title) {
      final pendingNativeTokenTransaction = await _signNativeTokenTransaction(
        tokenTitle: tokenTitle,
        tokenDecimals: tokenDecimals,
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerKeypair: ownerKeypair,
        commitment: commitment,
        isSendAll: isSendAll,
      );
      return pendingNativeTokenTransaction;
    } else {
      final pendingSPLTokenTransaction = _signSPLTokenTransaction(
        tokenTitle: tokenTitle,
        tokenDecimals: tokenDecimals,
        tokenMint: tokenMint!,
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerKeypair: ownerKeypair,
        commitment: commitment,
      );
      return pendingSPLTokenTransaction;
    }
  }

  Future<RecentBlockhash> _getRecentBlockhash(Commitment commitment) async {
    final latestBlockhash =
        await _client!.rpcClient.getLatestBlockhash(commitment: commitment).value;

    final recentBlockhash = RecentBlockhash(
      blockhash: latestBlockhash.blockhash,
      feeCalculator: const FeeCalculator(lamportsPerSignature: 500),
    );

    return recentBlockhash;
  }

  Message _getMessageForNativeTransaction(
    Ed25519HDKeyPair ownerKeypair,
    String destinationAddress,
    int lamports,
  ) {
    final instructions = [
      SystemInstruction.transfer(
        fundingAccount: ownerKeypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(destinationAddress),
        lamports: lamports,
      ),
    ];

    final message = Message(instructions: instructions);
    return message;
  }

  Future<double> _getFeeFromCompiledMessage(
    Message message,
    Ed25519HDPublicKey feePayer,
    RecentBlockhash recentBlockhash,
    Commitment commitment,
  ) async {
    final compile = message.compile(
      recentBlockhash: recentBlockhash.blockhash,
      feePayer: feePayer,
    );

    final base64Message = base64Encode(compile.toByteArray().toList());

    final fee = await getFeeForMessage(base64Message, commitment);

    return fee;
  }

  Future<PendingSolanaTransaction> _signNativeTokenTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    required Commitment commitment,
    required bool isSendAll,
  }) async {
    // Convert SOL to lamport
    int lamports = (inputAmount * lamportsPerSol).toInt();

    Message message = _getMessageForNativeTransaction(ownerKeypair, destinationAddress, lamports);

    final signers = [ownerKeypair];

    RecentBlockhash recentBlockhash = await _getRecentBlockhash(commitment);

    final fee = await _getFeeFromCompiledMessage(
      message,
      signers.first.publicKey,
      recentBlockhash,
      commitment,
    );

    SignedTx signedTx;
    if (isSendAll) {
      final feeInLamports = (fee * lamportsPerSol).toInt();
      final updatedLamports = lamports - feeInLamports;

      final updatedMessage =
          _getMessageForNativeTransaction(ownerKeypair, destinationAddress, updatedLamports);

      signedTx = await _signTransactionInternal(
        message: updatedMessage,
        signers: signers,
        commitment: commitment,
        recentBlockhash: recentBlockhash,
      );
    } else {
      signedTx = await _signTransactionInternal(
        message: message,
        signers: signers,
        commitment: commitment,
        recentBlockhash: recentBlockhash,
      );
    }

    sendTx() async => await sendTransaction(
          signedTransaction: signedTx,
          commitment: commitment,
        );

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      signedTransaction: signedTx,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );

    return pendingTransaction;
  }

  Future<PendingSolanaTransaction> _signSPLTokenTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required String tokenMint,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    required Commitment commitment,
  }) async {
    final destinationOwner = Ed25519HDPublicKey.fromBase58(destinationAddress);
    final mint = Ed25519HDPublicKey.fromBase58(tokenMint);

    ProgramAccount? associatedRecipientAccount;
    ProgramAccount? associatedSenderAccount;

    associatedRecipientAccount = await _client!.getAssociatedTokenAccount(
      mint: mint,
      owner: destinationOwner,
      commitment: commitment,
    );

    associatedSenderAccount = await _client!.getAssociatedTokenAccount(
      owner: ownerKeypair.publicKey,
      mint: mint,
      commitment: commitment,
    );

    // Throw an appropriate exception if the sender has no associated
    // token account
    if (associatedSenderAccount == null) {
      throw NoAssociatedTokenAccountException(ownerKeypair.address, mint.toBase58());
    }

    try {
      associatedRecipientAccount ??= await _client!.createAssociatedTokenAccount(
        mint: mint,
        owner: destinationOwner,
        funder: ownerKeypair,
      );
    } catch (e) {
      throw Exception('Insufficient SOL balance to complete this transaction: ${e.toString()}');
    }

    // Input by the user
    final amount = (inputAmount * pow(10, tokenDecimals)).toInt();

    final instruction = TokenInstruction.transfer(
      source: Ed25519HDPublicKey.fromBase58(associatedSenderAccount.pubkey),
      destination: Ed25519HDPublicKey.fromBase58(associatedRecipientAccount.pubkey),
      owner: ownerKeypair.publicKey,
      amount: amount,
    );

    final message = Message(instructions: [instruction]);

    final signers = [ownerKeypair];

    RecentBlockhash recentBlockhash = await _getRecentBlockhash(commitment);

    final fee = await _getFeeFromCompiledMessage(
      message,
      signers.first.publicKey,
      recentBlockhash,
      commitment,
    );

    final signedTx = await _signTransactionInternal(
      message: message,
      signers: signers,
      commitment: commitment,
      recentBlockhash: recentBlockhash,
    );

    sendTx() async => await sendTransaction(
          signedTransaction: signedTx,
          commitment: commitment,
        );

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      signedTransaction: signedTx,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
      fee: fee,
    );
    return pendingTransaction;
  }

  Future<SignedTx> _signTransactionInternal({
    required Message message,
    required List<Ed25519HDKeyPair> signers,
    required Commitment commitment,
    required RecentBlockhash recentBlockhash,
  }) async {
    final signedTx = await signTransaction(recentBlockhash, message, signers);

    return signedTx;
  }

  Future<String> sendTransaction({
    required SignedTx signedTransaction,
    required Commitment commitment,
  }) async {
    try {
      final signature = await _client!.rpcClient.sendTransaction(
        signedTransaction.encode(),
        preflightCommitment: commitment,
      );

      _client!.waitForSignatureStatus(signature, status: commitment);

      return signature;
    } catch (e) {
      print('Error while sending transaction: ${e.toString()}');
      throw Exception(e);
    }
  }

  Future<String?> getIconImageFromTokenUri(String uri) async {
    try {
      final response = await httpClient.get(Uri.parse(uri));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse['image'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching token image: \n${e.toString()}');
      return null;
    }
  }
}
