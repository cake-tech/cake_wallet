import 'package:cake_wallet/anonpay/anonpay_info_base.dart';

class AnonpayDonationLinkInfo implements AnonpayInfoBase{
  final String clearnetUrl;
  final String onionUrl;
  final String address;
  
  AnonpayDonationLinkInfo({
    required this.clearnetUrl,
    required this.onionUrl,
    required this.address,
  });
}