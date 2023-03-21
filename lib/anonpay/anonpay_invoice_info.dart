import 'package:cake_wallet/anonpay/anonpay_info_base.dart';
import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'anonpay_invoice_info.g.dart';

@HiveType(typeId: AnonpayInvoiceInfo.typeId)
class AnonpayInvoiceInfo extends HiveObject with Keyable implements AnonpayInfoBase {
  @HiveField(0)
  String invoiceId;
  @HiveField(1)
  String status;
  @HiveField(2)
  double? fiatAmount;
  @HiveField(3)
  String? fiatEquiv;
  @HiveField(4)
  double amountTo;
  @HiveField(5)
  String coinTo;
  @HiveField(6)
  String address;
  @HiveField(7)
  String clearnetUrl;
  @HiveField(8)
  String onionUrl;
  @HiveField(9)
  String clearnetStatusUrl;
  @HiveField(10)
  String onionStatusUrl;
  @HiveField(11)
  DateTime createdAt;
  @HiveField(12)
  String walletId;
  @HiveField(13)
  String provider;

  static const typeId = 10;
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
    required this.amountTo,
    required this.coinTo,
    required this.address,
    required this.createdAt,
    required this.walletId,
    required this.provider,
  });
}
