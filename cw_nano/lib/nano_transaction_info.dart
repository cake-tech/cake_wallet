import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/format_amount.dart";
import "package:cw_core/json_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";

class NanoTransactionInfo extends JsonTransactionInfo {
  NanoTransactionInfo({
    required super.id,
    required this.height,
    required super.amount,
    required super.direction,
    required this.confirmed,
    required super.date,
    required this.confirmations,
    required super.to,
    required super.from,
    this.tokenSymbol = "XNO",
  });

  factory NanoTransactionInfo.fromJson(Map<String, dynamic> data) => NanoTransactionInfo(
        id: data["id"] as String,
        height: data["height"] as int,
        amount: Money(BigInt.parse(data["amountRaw"] as String), CryptoCurrency.nano),
        direction: parseTransactionDirectionFromInt(data["direction"] as int),
        date: DateTime.fromMillisecondsSinceEpoch(data["date"] as int),
        confirmed: data["confirmed"] as bool,
        confirmations: data["confirmations"] as int,
        tokenSymbol: data["tokenSymbol"] as String,
        to: data["to"] as String,
        from: data["from"] as String,
      );

  @override
  final int height;
  final bool confirmed;
  @override
  final int confirmations;
  final String tokenSymbol;
  String? _fiatAmount;

  @override
  bool get isPending => !confirmed;

  @override
  String fiatAmount() => _fiatAmount ?? "";

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "height": height,
        "amountRaw": amount.amount.toString(),
        "direction": direction.index,
        "date": date.millisecondsSinceEpoch,
        "confirmed": confirmed,
        "confirmations": confirmations,
        "tokenSymbol": tokenSymbol,
        "to": to,
        "from": from,
      };
}
