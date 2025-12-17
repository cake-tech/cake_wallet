import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/wallet_type.dart';

class ZcashTransactionInfo extends TransactionInfo {
  ZcashTransactionInfo({
    required String id,
    required int amount,
    required int fee,
    required TransactionDirection direction,
    required bool isPending,
    required DateTime date,
    required int height,
    required int confirmations,
    required String to,
    String? memo,
    String? name,
  }) {
    this.id = id;
    this.amount = amount;
    this.fee = fee;
    this.height = height;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.confirmations = confirmations;
    this.to = to;
    if (memo != null && memo.isNotEmpty) {
      additionalInfo['memo'] = memo;
    }
    if (name != null && name.isNotEmpty) {
      additionalInfo['name'] = name;
    }
  }

  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(amount))} ${walletTypeToCryptoCurrency(WalletType.zcash).title}';

  @override
  String? feeFormatted() {
    if (fee == null || fee == 0) return null;
    return '${walletTypeToCryptoCurrency(WalletType.zcash).formatAmount(BigInt.from(fee!))} ${walletTypeToCryptoCurrency(WalletType.zcash).title}';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
  
  String? get memo => additionalInfo['memo'] as String?;
  String? get transactionName => additionalInfo['name'] as String?;
}
