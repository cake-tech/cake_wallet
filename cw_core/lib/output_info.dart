import 'package:cw_core/amount/money.dart';

class OutputInfo {
  const OutputInfo({
    required this.address,
    required this.sendAll,
    required this.isParsedAddress,
    required this.cryptoAmount,
    this.fiatAmount,
    this.note,
    this.extractedAddress,
    this.memo,
    this.extra = const {},
  });

  final String? fiatAmount;
  final Money cryptoAmount;
  final String address;
  final String? note;
  final String? extractedAddress;
  final bool sendAll;
  final bool isParsedAddress;
  final String? memo;
  final Map<String, dynamic> extra;
}
