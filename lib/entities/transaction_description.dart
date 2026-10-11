import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'transaction_description.part.dart';

// @HiveType(typeId: TransactionDescription.typeId)
class TransactionDescription extends HiveObject {
  TransactionDescription(
      {required this.id,
      this.recipientAddress,
      this.transactionNote,
      this.transactionKey,
      this.transactionHex});

  static const typeId = TRANSACTION_TYPE_ID;
  static const boxName = 'TransactionDescriptions';
  static const boxKey = 'transactionDescriptionsBoxKey';

  // @HiveField(0, defaultValue: '')
  String id;

  // @HiveField(1)
  String? recipientAddress;

  // @HiveField(2)
  String? transactionNote;

  // @HiveField(3)
  String? transactionKey;

  // @HiveField(4)
  String? transactionHex;

  String get note => transactionNote ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientAddress': recipientAddress,
        'transactionNote': transactionNote,
        'transactionKey': transactionKey,
        'transactionHex': transactionHex,
      };

  factory TransactionDescription.fromJson(Map<String, dynamic> json) {
    return TransactionDescription(
      id: json['id'] as String,
      recipientAddress: json['recipientAddress'] as String?,
      transactionNote: json['transactionNote'] as String?,
      transactionKey: json['transactionKey'] as String?,
      transactionHex: json['transactionHex'] as String?,
    );
  }
}
