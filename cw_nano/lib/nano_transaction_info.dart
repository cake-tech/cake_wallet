import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:nanoutil/nanoutil.dart';

class NanoTransactionInfo extends TransactionInfo {
  NanoTransactionInfo({
    required this.id,
    required this.height,
    required this.amountRaw,
    this.tokenSymbol = "XNO",
    required this.direction,
    required this.confirmed,
    required this.date,
    required this.confirmations,
    required this.to,
    required this.from,
  }) : this.amount = amountRaw.toInt();

  final String id;
  final int height;
  final int amount;
  final BigInt amountRaw;
  final TransactionDirection direction;
  final DateTime date;
  final bool confirmed;
  final int confirmations;
  final String tokenSymbol;
  final String? to;
  final String? from;
  String? _fiatAmount;

  bool get isPending => !this.confirmed;

  @override
  String amountFormatted() {
    final String amt =
        NanoAmounts.getRawAsUsableString(amountRaw.toString(), NanoAmounts.rawPerNano);
    final String acc = NanoAmounts.getRawAccuracy(amountRaw.toString(), NanoAmounts.rawPerNano);
    return "$acc$amt $tokenSymbol";
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => "0 XNO";

  factory NanoTransactionInfo.fromJson(Map<String, dynamic> data) {
    return NanoTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      amountRaw: BigInt.parse(data['amountRaw'] as String),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      confirmed: data['confirmed'] as bool,
      confirmations: data['confirmations'] as int,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'] as String,
      from: data['from'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'height': height,
        'amountRaw': amountRaw.toString(),
        'direction': direction.index,
        'date': date.millisecondsSinceEpoch,
        'confirmed': confirmed,
        'confirmations': confirmations,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
      };
}
