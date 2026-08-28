import "package:cw_core/amount/money.dart";
import "package:cw_core/format_amount.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_zcash/cw_zcash.dart";
import "package:cw_zcash/src/zkooltx.dart";

class ZcashTransactionInfo extends TransactionInfo {
  ZcashTransactionInfo({
    required super.id,
    required Money super.fee,
    required super.direction,
    required final bool isPending,
    required super.date,
    required final int height,
    required final int confirmations,
    required super.to,
    required super.amount,
    final String? memo,
    final TxType? txType,
    final bool isRotationReceive = false,
    final bool isShieldAction = false,
    final bool isIronwoodMigration = false,
  }) {
    this.height = height;
    this.isPending = isPending;
    this.confirmations = confirmations;
    if (memo != null && memo.isNotEmpty) {
      additionalInfo["memo"] = memo;
    }
    if (txType != null) {
      additionalInfo["txType"] = txType.name;
    }
    additionalInfo["isRotationReceive"] = isRotationReceive;
    additionalInfo["isAutoShield"] = isShieldAction || ZcashWalletService.isAutoshieldTx(txHash);
    additionalInfo["isIronwoodMigration"] = isIronwoodMigration;

    if (additionalInfo["isAutoShield"] == true) {
      additionalInfo["memo"] ??= "";
      additionalInfo["memo"] =
          '${additionalInfo['memo']}\nThis is an auto-shielding transaction. Enjoy default privacy!.'
              .trim();
    }
  }

  String? _fiatAmount;

  @override
  String fiatAmount() => _fiatAmount ?? "";

  @override
  void changeFiatAmount(final String amount) => _fiatAmount = formatAmount(amount);

  bool get _isMigration => additionalInfo["isIronwoodMigration"] == true;

  bool get _isAutoShield => additionalInfo["isAutoShield"] == true;

  @override
  String get title {
    if (_isMigration) {
      return "transaction_migration";
    }

    if (_isAutoShield) {
      return "shielding";
    }

    return super.title;
  }

  @override
  bool get hasStatus => _isMigration ? false : super.hasStatus;

  String? get memo => additionalInfo["memo"] as String?;
}
