import 'dart:async';
import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class SolanaWalletClient {
  final httpClient = http.Client();
  SolanaClient? _client;

  bool connect(Node node) {
    try {
      _client = SolanaClient(rpcUrl: node.uri, websocketUrl: node.uri);
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

  Future<ProgramAccountsResult> getSPLTokenAccounts(String mintAddress, String publicKey) async {
    final tokenAccounts = await _client!.rpcClient.getTokenAccountsByOwner(
      publicKey,
      TokenAccountsFilter.byMint(mintAddress),
      commitment: Commitment.confirmed,
      encoding: Encoding.jsonParsed,
    );
    return tokenAccounts;
  }

  Future<SolanaBalance> getSplTokenBalance(String mintAddress, String publicKey) async {
    // Fetch the token accounts (a token can have multiple accounts for various uses)
    final tokenAccounts = await getSPLTokenAccounts(mintAddress, publicKey);

    // Handle scenario where there is no token account
    if (tokenAccounts.value.isEmpty) {
      return SolanaBalance(0.0);
    }

    // Sum the balances of all accounts with the specified mint address
    double totalBalance = 0.0;

    for (var programAccount in tokenAccounts.value) {
      final lamports = programAccount.account.lamports;

      final solBalance = lamports / lamportsPerSol;

      totalBalance += solBalance;
    }

    return SolanaBalance(totalBalance);
  }

  Future<double> getGasForMessage(String message) async {
    try {
      final gasPrice = await _client!.rpcClient.getFeeForMessage(message) ?? 0;
      final fee = gasPrice / lamportsPerSol;
      return fee;
    } catch (_) {
      return 0;
    }
  }

  /// Load the Address's transactions into the account
  Future<List<SolanaTransactionModel>> fetchTransactions(Ed25519HDPublicKey address) async {
    List<SolanaTransactionModel> transactions = [];

    try {
      final response = await _client!.rpcClient.getTransactionsList(
        address,
        commitment: Commitment.confirmed,
      );

      for (final tx in response) {
        if (tx.transaction is ParsedTransaction) {
          final parsedTx = (tx.transaction as ParsedTransaction);

          final message = parsedTx.message;

          for (final instruction in message.instructions) {
            if (instruction is ParsedInstruction) {
              instruction.map(
                system: (data) {
                  data.parsed.map(
                    transfer: (data) {
                      ParsedSystemTransferInformation transfer = data.info;
                      bool receivedOrNot = transfer.destination == address.toBase58();
                      double amount = transfer.lamports.toDouble() / lamportsPerSol;

                      transactions.add(
                        SolanaTransactionModel(
                          id: parsedTx.signatures.first,
                          from: transfer.source,
                          to: transfer.destination,
                          amount: amount,
                          isIncomingTransaction: receivedOrNot,
                          programId: SystemProgram.programId,
                          blockTimeInInt: tx.blockTime!,
                        ),
                      );
                    },
                    transferChecked: (_) {},
                    unsupported: (_) {
                      transactions.add(UnsupportedTransaction(tx.blockTime!));
                    },
                  );
                },
                splToken: (data) {
                  data.parsed.map(
                    transfer: (data) {
                      SplTokenTransferInfo transfer = data.info;
                      bool receivedOrNot = transfer.destination == address.toBase58();
                      double amount = double.tryParse(transfer.amount) ?? 0.0;
                      transactions.add(
                        SolanaTransactionModel(
                          id: parsedTx.signatures.first,
                          from: transfer.source,
                          to: transfer.destination,
                          amount: amount,
                          isIncomingTransaction: receivedOrNot,
                          programId: TokenProgram.programId,
                          blockTimeInInt: tx.blockTime!,
                        ),
                      );
                    },
                    transferChecked: (data) {},
                    generic: (data) {},
                  );
                },
                memo: (_) {},
                unsupported: (a) {
                  transactions.add(UnsupportedTransaction(tx.blockTime!));
                },
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

  void stop() {}

  SolanaClient? get getSolanaClient => _client;

  Future<PendingSolanaTransaction> signTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required String tokenMint,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    List<String> references = const [],
  }) async {
    print('Insdide swigned transaction function');
    const commitment = Commitment.finalized;

    final latestBlockhash =
        await _client!.rpcClient.getLatestBlockhash(commitment: commitment).value;

    if (tokenTitle == CryptoCurrency.sol.title) {
      final pendingNativeTokenTransaction = await _signNativeTokenTransaction(
        tokenTitle: tokenTitle,
        tokenDecimals: tokenDecimals,
        tokenMint: tokenMint,
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerKeypair: ownerKeypair,
        latestBlockhash: latestBlockhash,
        commitment: commitment,
      );
      return pendingNativeTokenTransaction;
    } else {
      final pendingSPLTokenTransaction = _signSPLTokenTransaction(
        tokenTitle: tokenTitle,
        tokenDecimals: tokenDecimals,
        tokenMint: tokenMint,
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerKeypair: ownerKeypair,
        latestBlockhash: latestBlockhash,
        commitment: commitment,
      );
      return pendingSPLTokenTransaction;
    }
  }

  Future<PendingSolanaTransaction> _signNativeTokenTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required String tokenMint,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    required LatestBlockhash latestBlockhash,
    required Commitment commitment,
  }) async {
    print('Inside Sign Native Token Transaction Function');
    // Convert SOL to lamport
    int lamports = (inputAmount * lamportsPerSol).toInt();

    final instructions = [
      SystemInstruction.transfer(
        fundingAccount: ownerKeypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(destinationAddress),
        lamports: lamports,
      ),
    ];

    final message = Message(instructions: instructions);
    final signers = [ownerKeypair];

    final signedTx = await _signTransactionInternal(
      message: message,
      signers: signers,
      commitment: commitment,
      latestBlockhash: latestBlockhash,
    );

    print('SignedTx: ${signedTx.encode()}');

    sendTx() async => await sendTransaction(
          signedTransaction: signedTx,
          commitment: commitment,
        );

    print('SendTx compiled');

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      signedTransaction: signedTx,
      destinationAddress: destinationAddress,
      sendTransaction: sendTx,
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
    required LatestBlockhash latestBlockhash,
    required Commitment commitment,
  }) async {
    final destinationOwner = Ed25519HDPublicKey.fromBase58(destinationAddress);
    final mint = Ed25519HDPublicKey.fromBase58(tokenMint);

    final associatedRecipientAccount = await _client!.getAssociatedTokenAccount(
      mint: mint,
      owner: destinationOwner,
      commitment: commitment,
    );
    final associatedSenderAccount = await _client!.getAssociatedTokenAccount(
      owner: ownerKeypair.publicKey,
      mint: mint,
      commitment: commitment,
    );

    // Throw an appropriate exception if the sender has no associated
    // token account
    if (associatedSenderAccount == null) {
      throw NoAssociatedTokenAccountException(ownerKeypair.address, mint.toBase58());
    }

    // Also throw an adequate exception if the recipient has no associated
    // token account
    if (associatedRecipientAccount == null) {
      throw NoAssociatedTokenAccountException(
        destinationOwner.toBase58(),
        mint.toBase58(),
      );
    }

    // Input by the user
    int userAmount = inputAmount.toInt();

    int amount = int.parse('$userAmount${'0' * tokenDecimals}');

    final instruction = TokenInstruction.transfer(
      source: Ed25519HDPublicKey.fromBase58(associatedSenderAccount.pubkey),
      destination: Ed25519HDPublicKey.fromBase58(associatedRecipientAccount.pubkey),
      owner: ownerKeypair.publicKey,
      amount: amount,
    );

    final message = Message(instructions: [instruction]);
    final signers = [ownerKeypair];

    final signedTx = await _signTransactionInternal(
      message: message,
      signers: signers,
      commitment: commitment,
      latestBlockhash: latestBlockhash,
    );

    final pendingTransaction = PendingSolanaTransaction(
      amount: inputAmount,
      signedTransaction: signedTx,
      destinationAddress: destinationAddress,
      sendTransaction: sendTransaction,
    );
    return pendingTransaction;
  }

  Future<SignedTx> _signTransactionInternal({
    required Message message,
    required List<Ed25519HDKeyPair> signers,
    required Commitment commitment,
    required LatestBlockhash latestBlockhash,
  }) async {
    print('Inside Sign Ternasaction internal Function');
    if (signers.isEmpty) {
      throw const FormatException('you must specify at least on signer');
    }

    final CompiledMessage compiledMessage = message.compile(
      recentBlockhash: latestBlockhash.blockhash,
      feePayer: signers.first.publicKey,
    );

    final int requiredSignaturesCount = compiledMessage.requiredSignatureCount;
    if (signers.length != requiredSignaturesCount) {
      throw FormatException(
        'your message requires $requiredSignaturesCount signatures but '
        'you provided ${signers.length}',
      );
    }

    final List<Signature> signatures = await Future.wait(
      signers.map((signer) => signer.sign(compiledMessage.toByteArray())),
    );

    final signedTx = SignedTx(
      compiledMessage: compiledMessage,
      signatures: signatures,
    );

    return signedTx;
  }

  Future<String> sendTransaction({
    required SignedTx signedTransaction,
    required Commitment commitment,
  }) async {
    final signature = await _client!.rpcClient.sendTransaction(signedTransaction.encode());

    await _client!.waitForSignatureStatus(signature, status: commitment);

    return signature;
  }
}
