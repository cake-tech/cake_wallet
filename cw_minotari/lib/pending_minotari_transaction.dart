import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_minotari/minotari_amount_format.dart';

class PendingMinotariTransaction with PendingTransaction {
  final int amount;
  final int fee;
  final String recipientAddress;
  final Future<String> Function() sendTransaction;

  String? _txId;

  PendingMinotariTransaction({
    required this.amount,
    required this.fee,
    required this.recipientAddress,
    required this.sendTransaction,
  });

  @override
  String get id => _txId ?? '';

  @override
  String get amountFormatted =>
      '${minotariAmountToString(amount: amount)} ${CryptoCurrency.xtm.title}';

  @override
  String get feeFormatted =>
      '${minotariAmountToString(amount: fee)} ${CryptoCurrency.xtm.title}';

  @override
  String get feeFormattedValue => minotariAmountToString(amount: fee);

  @override
  String get hex => _txId ?? '';

  @override
  Future<void> commit() async {
    _txId = await sendTransaction();
  }

  @override
  Future<Map<String, String>> commitUR() async {
    // UR (Uniform Resources) not supported for Minotari
    throw UnimplementedError('UR not supported for Minotari');
  }
}

class MinotariTransactionCredentials {
  final List<OutputInfo> outputs;

  MinotariTransactionCredentials(this.outputs);
}
