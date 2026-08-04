import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/zkooltx.dart';

class ZcashTransactionInfo extends TransactionInfo {
  ZcashTransactionInfo({
    required final String id,
    required final Money amount,
    required final Money fee,
    required final TransactionDirection direction,
    required final bool isPending,
    required final DateTime date,
    required final int height,
    required final int confirmations,
    required final String to,
    final String? memo,
    final TxType? txType,
    final bool isRotationReceive = false,
    final bool isShieldAction = false,
    final bool isIronwoodMigration = false,
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
    if (txType != null) {
      additionalInfo['txType'] = txType.name;
    }
    additionalInfo['isRotationReceive'] = isRotationReceive;
    additionalInfo['isAutoShield'] = isShieldAction || ZcashWalletService.isAutoshieldTx(txHash);
    additionalInfo['isIronwoodMigration'] = isIronwoodMigration;

    if (additionalInfo['isAutoShield'] == true) {
      additionalInfo['memo'] ??= '';
      additionalInfo['memo'] =
          '${additionalInfo['memo']}\nThis is an auto-shielding transaction. Enjoy default privacy!.'
              .trim();
    }
  }

  String? _fiatAmount;

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(final String amount) => _fiatAmount = formatAmount(amount);

  String? get memo => additionalInfo['memo'] as String?;
}
