import 'dart:convert';

import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'transaction_description.g.dart';

@HiveType(typeId: TransactionDescription.typeId)
class TransactionDescription extends HiveObject {
  TransactionDescription(
      {required this.id,
      this.recipientAddress,
      this.transactionNote,
      this.historicalRatesJson});

  static const typeId = TRANSACTION_TYPE_ID;
  static const boxName = 'TransactionDescriptions';
  static const boxKey = 'transactionDescriptionsBoxKey';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1)
  String? recipientAddress;

  @HiveField(2)
  String? transactionNote;

  @HiveField(3)
  String? historicalRatesJson;


  String get note => transactionNote ?? '';

  Map<String, String> get historicalRates =>
      historicalRatesJson != null ? Map<String, String>.from(jsonDecode(historicalRatesJson!) as Map<dynamic, dynamic>) : {};

  set historicalRates(Map<String, String> value) {
    historicalRatesJson = jsonEncode(value);
  }
}
