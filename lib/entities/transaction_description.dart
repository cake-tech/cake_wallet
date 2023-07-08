import 'package:hive/hive.dart';

part 'transaction_description.g.dart';

@HiveType(typeId: TransactionDescription.typeId)
class TransactionDescription extends HiveObject {
  TransactionDescription(
      {required this.id,
      this.recipientAddress,
      this.transactionNote,
      this.historicalFiatRaw,
      this.historicalFiatRate});

  static const typeId = 2;
  static const boxName = 'TransactionDescriptions';
  static const boxKey = 'transactionDescriptionsBoxKey';

  @HiveField(0, defaultValue: '')
  String id;

  @HiveField(1)
  String? recipientAddress;

  @HiveField(2)
  String? transactionNote;

  @HiveField(3)
  String? historicalFiatRaw;

  @HiveField(4)
  double? historicalFiatRate;

  String get note => transactionNote ?? '';

  String get historicalFiat => historicalFiatRaw ?? '';
}
