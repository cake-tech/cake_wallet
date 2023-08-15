import 'package:cake_wallet/anonpay/anonpay_info_base.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'anonpay_invoice_info.g.dart';

@HiveType(typeId: AnonpayInvoiceInfo.typeId)
class AnonpayInvoiceInfo extends HiveObject with Keyable implements AnonpayInfoBase {
  @HiveField(0)
  final String invoiceId;
  @HiveField(1)
  String status;
  @HiveField(2)
  final double? fiatAmount;
  @HiveField(3)
  final String? fiatEquiv;
  @HiveField(4)
  final double? amountTo;
  @HiveField(5)
  final String coinTo;
  @HiveField(6)
  final String address;
  @HiveField(7)
  final String clearnetUrl;
  @HiveField(8)
  final String onionUrl;
  @HiveField(9)
  final String clearnetStatusUrl;
  @HiveField(10)
  final String onionStatusUrl;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final String walletId;
  @HiveField(13)
  final String provider;

  static const typeId = ANONPAY_INVOICE_INFO_TYPE_ID;
  static const boxName = 'AnonpayInvoiceInfo';

  AnonpayInvoiceInfo({
    required this.invoiceId,
    required this.clearnetUrl,
    required this.onionUrl,
    required this.clearnetStatusUrl,
    required this.onionStatusUrl,
    required this.status,
    this.fiatAmount,
    this.fiatEquiv,
    this.amountTo,
    required this.coinTo,
    required this.address,
    required this.createdAt,
    required this.walletId,
    required this.provider,
  });
}
