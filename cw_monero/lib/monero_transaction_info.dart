import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.txHash, this.height, this.direction, this.date, this.isPending,
      this.amount, this.accountIndex, this.addressIndex, this.fee, this.confirmations)
      : id = "${txHash}_${amount}_${accountIndex}_${addressIndex}";

  final String id;
  final String txHash;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  final int fee;
  final int addressIndex;
  final int confirmations;
  String? recipientAddress;
  String? key;
  String? _fiatAmount;

  @override
  String amountFormatted() => '${CryptoCurrency.xmr.formatAmount(BigInt.from(amount))} XMR';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${CryptoCurrency.xmr.formatAmount(BigInt.from(fee))} XMR';
}
