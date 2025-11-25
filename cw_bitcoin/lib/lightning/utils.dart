import 'package:cw_core/lnurl.dart';

String getLnurlOfLightningAddress(String lightningAddress) {
  final parts = lightningAddress.split("@");

  final name = parts.first;
  final domain = parts.last;
  return encodeLNURL("https://$domain/.well-known/lnurlp/$name");
}
