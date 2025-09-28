import 'package:cake_wallet/core/yat_service.dart';

class YatRecord {
  YatRecord({
    required this.address,
    required this.tag,
  });

  final String address;
  final String tag;

  factory YatRecord.fromJson(Map<String, dynamic> json, String tag) =>
      YatRecord(address: (json['address'] ?? '').toString(), tag: tag);

  bool get isMoneroSub => tag == YatService.MONERO_SUB_ADDRESS;

  @override
  String toString() => 'YatRecord(tag: $tag, address: $address)';
}
