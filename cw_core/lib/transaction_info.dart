import "package:cw_core/action_list_item.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/format_amount.dart";
import "package:cw_core/keyable.dart";
import "package:cw_core/transaction_direction.dart";

abstract class TransactionInfo extends Object with Keyable, HistoryListItem {
  TransactionInfo({
    required this.id,
    required this.amount,
    required this.direction,
    required this.date,
    this.fee,
    this.to,
    this.from,
  });

  @override
  final String id;
  final Money amount;
  String get txHash => id;
  final Money? fee;
  final TransactionDirection direction;
  late bool isPending;
  @override
  final DateTime date;
  int? height;
  int confirmations = 0;
  final String? to;
  final String? from;
  List<String>? inputAddresses;
  List<String>? outputAddresses;

  String get title {
    final incoming = direction == TransactionDirection.incoming;

    if (isPending) {
      return incoming ? "receiving" : "sending";
    }

    return incoming ? "received" : "sent";
  }

  bool get hasStatus => isPending;

  int get neededConfirmations => 0;

  String? get status {
    if (neededConfirmations > 0 && confirmations < neededConfirmations) {
      return "($confirmations/$neededConfirmations)";
    }

    return null;
  }

  @override
  dynamic get keyIndex => id;

  CryptoCurrency? get assetOfTransaction {
    final currency = amount.currency;
    return currency is CryptoCurrency ? currency : null;
  }

  Map<String, dynamic> additionalInfo = {};

  String? _fiatAmount;
  String fiatAmount() => _fiatAmount ?? "";
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
}
