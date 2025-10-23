import 'dart:typed_data';

import 'package:cw_core/format_fixed.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart' as Hex;

class PendingEVMChainTransaction with PendingTransaction {
  final Function sendTransaction;
  final Uint8List signedTransaction;
  final BigInt fee;
  final String feeCurrency;
  final String amount;
  final int exponent;
  final bool isInfiniteApproval;

  PendingEVMChainTransaction({
    required this.sendTransaction,
    required this.signedTransaction,
    required this.fee,
    required this.feeCurrency,
    required this.amount,
    required this.exponent,
    this.isInfiniteApproval = false,
  });

  @override
  String get amountFormatted {
    if (isInfiniteApproval) return "∞";
    return formatFixed(BigInt.parse(amount), exponent);
  }

  @override
  Future<void> commit() async => await sendTransaction();

  @override
  String get feeFormatted => "$feeFormattedValue $feeCurrency";

  @override
  String get feeFormattedValue => formatFixed(fee, 18, fractionalDigits: 10);

  @override
  String get hex => bytesToHex(signedTransaction, include0x: true);

  @override
  String get id {
    final String eip1559Hex = '0x02${hex.substring(2)}';
    final Uint8List bytes = Uint8List.fromList(Hex.HEX.decode(eip1559Hex.substring(2)));

    final txid = keccak256(bytes);

    return '0x${Hex.HEX.encode(txid)}';
  }

  @override
  String? get evmTxHashFromRawHex {
    final no0x = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = Uint8List.fromList(Hex.HEX.decode(no0x));
    final digest = keccak256(bytes);
    return '0x${Hex.HEX.encode(digest)}';
  }

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
