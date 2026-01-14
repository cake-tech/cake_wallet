import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_minotari/minotari_amount_format.dart';

class MinotariTransactionInfo extends TransactionInfo {
  MinotariTransactionInfo({
    required String id,
    required int amount,
    required DateTime date,
    required TransactionDirection direction,
    required bool isPending,
    int? fee,
    int? height,
    int confirmations = 0,
  }) {
    this.id = id;
    this.txHash = id;
    this.amount = amount;
    this.date = date;
    this.direction = direction;
    this.isPending = isPending;
    this.fee = fee;
    this.height = height;
    this.confirmations = confirmations;
  }

  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(minotariAmountToString(amount: amount))} ${CryptoCurrency.xtm.title}';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String? feeFormatted() {
    if (fee == null) return null;
    return '${formatAmount(minotariAmountToString(amount: fee!))} ${CryptoCurrency.xtm.title}';
  }
}
