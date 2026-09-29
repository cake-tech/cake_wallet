import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/solana_serialized_transaction_credentials.dart';
import 'package:cw_solana/pending_solana_transaction.dart';
import 'package:on_chain/solana/solana.dart';

Future<PendingSolanaTransaction> prepareSerializedSolanaTransaction({
  required SolanaSerializedTransactionCredentials credentials,
  required SolanaPrivateKey privateKey,
  required SolanaRPC provider,
  required bool Function() isCurrentProvider,
  required Money nativeBalance,
}) async {
  final raw = Base58Decoder.decode(credentials.transactionBase58);
  final transaction = SolanaTransaction.deserialize(raw);
  final owner = privateKey.publicKey().toAddress();
  if (transaction.signers.isEmpty ||
      transaction.signers.first != owner ||
      Base58Encoder.encode(transaction.serialize()) != credentials.transactionBase58) {
    throw StateError('Supplied Solana transaction has a different fee payer or encoding');
  }
  final message = transaction.serializeMessage();
  final genesis = await provider.request(SolanaRPCGetGenesisHash());
  if (genesis != '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d') {
    throw StateError('Supplied Solana swaps require mainnet');
  }
  final lamports = await provider.request(SolanaRPCGetFeeForMessage(
      encodedMessage: base64Encode(message), commitment: Commitment.confirmed));
  if (lamports == null || !isCurrentProvider()) {
    throw StateError('Solana fee or wallet connection is unavailable');
  }
  final fee = Money(lamports, CryptoCurrency.sol);
  final nativeRequired = fee.amount +
      (credentials.amount.currency == CryptoCurrency.sol ? credentials.amount.amount : BigInt.zero);
  if (nativeBalance.amount < nativeRequired) throw StateError('Insufficient SOL for swap and fees');
  transaction.addSignature(owner, privateKey.sign(message));
  // Signature verification and message preservation, not instruction decoding.
  final signed = transaction.serialize(verifySignatures: true);
  if (Base58Encoder.encode(transaction.serializeMessage()) != Base58Encoder.encode(message)) {
    throw StateError('Supplied Solana message changed while signing');
  }
  final wire = Base58Encoder.encode(signed);
  final id = Base58Encoder.encode(transaction.signatures.first);
  return PendingSolanaTransaction(
    amount: credentials.amount,
    fee: fee,
    serializedTransaction: wire,
    destinationAddress: credentials.destinationAddress,
    sendTransaction: () async {
      if (!isCurrentProvider()) throw StateError('Solana wallet connection changed');
      final returned = await provider.request(SolanaRPCSendTransaction(
          encodedTransaction: wire, commitment: Commitment.confirmed, skipPreflight: false));
      if (returned != id) throw StateError('Solana returned a different transaction ID');
      return id;
    },
  );
}
