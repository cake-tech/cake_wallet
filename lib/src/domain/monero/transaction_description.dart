import 'package:hive/hive.dart';

part 'transaction_description.g.dart';

@HiveType()
class TransactionDescription extends HiveObject {
  static const boxName = 'TransactionDescriptions';

  @HiveField(0)
  String id;

  @HiveField(1)
  String recipientAddress;

  TransactionDescription({this.id, this.recipientAddress});
}