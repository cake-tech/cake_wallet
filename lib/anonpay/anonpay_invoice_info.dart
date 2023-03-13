import 'package:cake_wallet/anonpay/anonpay_provider_description.dart';
import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'anonpay_invoice_info.g.dart';

@HiveType(typeId: AnonpayInvoiceInfo.typeId)
class AnonpayInvoiceInfo extends HiveObject with Keyable {
  @HiveField(0)
  String? invoiceId;
  @HiveField(1)
  String? status;
  @HiveField(2)
  String? fiatAmount;
  @HiveField(3)
  String? fiatEquiv;
  @HiveField(4)
  double? amountTo;
  @HiveField(5)
  String? coinTo;
  @HiveField(6)
  String? address;
  @HiveField(7)
  String clearnetUrl;
  @HiveField(8)
  String onionUrl;
  @HiveField(9)
  String? clearnetStatusUrl;
  @HiveField(10)
  String? onionStatusUrl;
  @HiveField(11)
  DateTime? createdAt;
  @HiveField(12)
  String? walletId;
  @HiveField(13, defaultValue: 0)
  late int providerRaw;

  AnonpayProviderDescription get provider =>
      AnonpayProviderDescription.deserialize(raw: providerRaw);

  static const typeId = 10;
  static const boxName = 'AnonpayInvoiceInfo';

  AnonpayInvoiceInfo({
    this.invoiceId,
    required this.clearnetUrl,
    required this.onionUrl,
    this.clearnetStatusUrl,
    this.onionStatusUrl,
    this.status,
    this.fiatAmount,
    this.fiatEquiv,
    this.amountTo,
    this.coinTo,
    this.address,
    this.createdAt,
    this.walletId,
    AnonpayProviderDescription? provider,
  }) {
    if (provider != null) {
      providerRaw = provider.raw;
    }
  }
}
