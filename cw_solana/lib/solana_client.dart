import 'dart:async';
import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:cw_solana/solana_balance.dart';
import 'package:cw_solana/solana_transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:solana/dto.dart';
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
    // Fetch the token
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

  int get chainId => 1;

  Future getTransactionDetails(String transactionHash) async {}

  void stop() {
    // _client?.rpcClient .dispose();
  }

  SolanaClient? getSolanaClient() => _client;

  /// Fetch the USD value of a token using the Coingecko API
  Future<Map<String, double>> getTokenUsdValue(List<String> tokens) async {
    try {
      Map<String, String> headers = {};
      headers['Accept'] = 'application/json';
      headers['Access-Control-Allow-Origin'] = '*';
      http.Response response = await http.get(
        Uri.http(
          'api.coingecko.com',
          '/api/v3/simple/price',
          {
            'ids': tokens.join(','),
            'vs_currencies': 'USD',
          },
        ),
        headers: headers,
      );

      final body = json.decode(response.body) as Map;
      Map<String, double> values = {};
      for (final token in body.keys) {
        double? usdTokenValue = body[token]['usd'];
        if (usdTokenValue != null) {
          values[token] = usdTokenValue;
        }
      }

      return values;
    } catch (err) {
      return {tokens[0]: 0};
    }
  }

  /// Send SOLs to an adress
  Future<String> sendLamportsTo(
    String destinationAddress,
    int amount,
    Ed25519HDKeyPair ownerKeypair, {
    List<String> references = const [],
  }) async {
    final signature = await _client!.transferLamports(
      source: ownerKeypair,
      destination: Ed25519HDPublicKey.fromBase58(destinationAddress),
      lamports: amount,
    );

    return signature;
  }

  /// Send SPL Token to an adress
  Future<String> sendSPLTokenTo(
    String destinationAddress,
    String tokenMint,
    int amount,
    Ed25519HDKeyPair ownerKeypair, {
    List<String> references = const [],
  }) async {
    final signature = await _client!.transferSplToken(
      mint: Ed25519HDPublicKey.fromBase58(tokenMint),
      destination: Ed25519HDPublicKey.fromBase58(destinationAddress),
      amount: amount,
      owner: ownerKeypair,
    );

    return signature;
  }

  Future<PendingSolanaTransaction> sendTransaction({
    required String tokenTitle,
    required int tokenDecimals,
    required String tokenMint,
    required double inputAmount,
    required String destinationAddress,
    required Ed25519HDKeyPair ownerKeypair,
    List<String> references = const [],
  }) async {
    if (tokenTitle == CryptoCurrency.sol.title) {
      // Convert SOL to lamport
      int lamports = (inputAmount * lamportsPerSol).toInt();

      final signature = await sendLamportsTo(
        destinationAddress,
        lamports,
        ownerKeypair,
        references: references,
      );

      return PendingSolanaTransaction(
        amount: inputAmount,
        signature: signature,
        destinationAddress: destinationAddress,
      );
    }

    // Input by the user
    int userAmount = inputAmount.toInt();

    int amount = int.parse('$userAmount${'0' * tokenDecimals}');

    final signature = await sendSPLTokenTo(
      destinationAddress,
      tokenMint,
      amount,
      ownerKeypair,
      references: references,
    );

    return PendingSolanaTransaction(
      amount: inputAmount,
      signature: signature,
      destinationAddress: destinationAddress,
    );
  }
}
