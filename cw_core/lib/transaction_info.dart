import 'package:cw_core/amount/money.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/keyable.dart';

abstract class TransactionInfo extends Object with Keyable {
  late String id;
  late String txHash = id;
  late Money amount;
  Money? fee;
  late TransactionDirection direction;
  late bool isPending;
  late DateTime date;
  int? height;
  int confirmations = 0;
  String? to;
  String? from;
  String? evmSignatureName;
  bool? isReplaced;
  List<String>? inputAddresses;
  List<String>? outputAddresses;

  @override
  dynamic get keyIndex => id;

  Map<String, dynamic> additionalInfo = {};

  String? _fiatAmount;
  String fiatAmount() => _fiatAmount ?? '';
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
}
