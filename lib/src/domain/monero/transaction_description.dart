import 'package:hive/hive.dart';

part 'transaction_description.g.dart';

@HiveType(typeId: 2)
class TransactionDescription extends HiveObject {
  TransactionDescription({this.id, this.recipientAddress});

  static const boxName = 'TransactionDescriptions';

  @HiveField(0)
  String id;

  @HiveField(1)
  String recipientAddress;
}
