import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_solana/default_spl_tokens.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:cw_solana/spl_token.dart';
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
      bool isChainStackNode = false;

      if (node.uriRaw == 'solana-mainnet.core.chainstack.com') {
        isChainStackNode = true;
        String chainStackApiKey = secrets.chainStackApiKey;

        rpcUri = Uri.https(node.uriRaw, '/$chainStackApiKey');
        webSocketUrl = 'wss://${node.uriRaw}/ws/$chainStackApiKey';
      } else {
        webSocketUrl = 'wss://${node.uriRaw}';
      }

      _client = SolanaClient(
        rpcUrl: isChainStackNode ? rpcUri! : node.uri,
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

    // Using mainnet beta node to fetch transactions.
    final mainNetBetaConfig = {"uri": "api.mainnet-beta.solana.com"};

    final mainNetBetaNode = Node.fromMap(mainNetBetaConfig);
    mainNetBetaNode.type = WalletType.solana;

    final mainNetBetaSolanaClient = SolanaClient(
      rpcUrl: mainNetBetaNode.uri,
      websocketUrl: Uri.parse('wss://${mainNetBetaNode.uriRaw}'),
      timeout: const Duration(minutes: 2),
    );

    try {
      final response = await mainNetBetaSolanaClient.rpcClient.getTransactionsList(
        address,
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
                system: (data) {
                  data.parsed.map(
                    transfer: (data) {
                      ParsedSystemTransferInformation transfer = data.info;
                      bool isOutgoingTx = transfer.source == address.toBase58();

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
                splToken: (data) {
                  data.parsed.map(
                    transfer: (data) {
                      final mintAddress = tx.meta?.postTokenBalances.first.mint ?? '';
                      final tokens = DefaultSPLTokens().initialSPLTokens;
                      SPLToken? token;
                      try {
                        token = tokens.firstWhere((token) => token.mintAddress == mintAddress);
                      } catch (e) {
                        print('Error getting the token from default tokens: $e');
                      }

                      SplTokenTransferInfo transfer = data.info;
                      bool isOutgoingTx = message.accountKeys[0].pubkey == address.toBase58();

                      double amount =
                          (double.tryParse(transfer.amount) ?? 0.0) / pow(10, token?.decimal ?? 9);

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
                          tokenSymbol: token?.symbol ?? 'SOL',
                        ),
                      );
                    },
                    transferChecked: (data) {
                      final mintAddress = tx.meta?.postTokenBalances.first.mint ?? '';
                      final tokens = DefaultSPLTokens().initialSPLTokens;

                      String tokenSymbol;
                      try {
                        tokenSymbol =
                            tokens.firstWhere((token) => token.mintAddress == mintAddress).symbol;
                      } catch (e) {
                        tokenSymbol = 'SOL';
                        print('Error getting the tokenSymbol from default tokens: $e');
                      }

                      SplTokenTransferCheckedInfo transfer = data.info;
                      bool isOutgoingTx = message.accountKeys[0].pubkey == address.toBase58();
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
                          tokenSymbol: tokenSymbol,
                        ),
                      );
                    },
                    generic: (data) {},
                  );
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

  void stop() {}

  SolanaClient? get getSolanaClient => _client;

  Future<PendingSolanaTransaction> signSolanaTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    String? tokenMint,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    List<String> references = const [],
  }) async {
    const commitment = Commitment.finalized;

    final latestBlockhash =
        await _client!.rpcClient.getLatestBlockhash(commitment: commitment).value;

    final recentBlockhash = RecentBlockhash(
      blockhash: latestBlockhash.blockhash,
      feeCalculator: const FeeCalculator(
        lamportsPerSignature: 500,
      ),
    );

    if (tokenTitle == CryptoCurrency.sol.title) {
      final pendingNativeTokenTransaction = await _signNativeTokenTransaction(
        tokenTitle: tokenTitle,
        tokenDecimals: tokenDecimals,
        inputAmount: inputAmount,
        destinationAddress: destinationAddress,
        ownerKeypair: ownerKeypair,
        recentBlockhash: recentBlockhash,
        commitment: commitment,
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
        recentBlockhash: recentBlockhash,
        commitment: commitment,
      );
      return pendingSPLTokenTransaction;
    }
  }

  Future<int> getMinimumBalanceForRentExemption(String publicKey) async {
    final rent = _client!.rpcClient.getMinimumBalanceForRentExemption(
      TokenProgram.neededAccountSpace,
    );

    return rent;
  }

  Future<PendingSolanaTransaction> _signNativeTokenTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    required RecentBlockhash recentBlockhash,
    required Commitment commitment,
  }) async {
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
      recentBlockhash: recentBlockhash,
    );

    final compile = message.compile(
      recentBlockhash: recentBlockhash.blockhash,
      feePayer: signers.first.publicKey,
    );

    final base64Message = base64Encode(compile.toByteArray().toList());

    final fee = await getGasForMessage(base64Message);

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
    required RecentBlockhash recentBlockhash,
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
      throw Exception(
        'Error while creating an associated token account for the recipient: ${e.toString()}',
      );
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

    final signedTx = await _signTransactionInternal(
      message: message,
      signers: signers,
      commitment: commitment,
      recentBlockhash: recentBlockhash,
    );
    final compile = message.compile(
      recentBlockhash: recentBlockhash.blockhash,
      feePayer: signers.first.publicKey,
    );

    final base64Message = base64Encode(compile.toByteArray().toList());

    final fee = await getGasForMessage(base64Message);

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
    final signedTx = await signTransaction(
      recentBlockhash,
      message,
      signers,
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
