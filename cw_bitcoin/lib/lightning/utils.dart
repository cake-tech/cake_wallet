import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_core/lnurl.dart";

String getLnurlOfLightningAddress(String lightningAddress) {
  final parts = lightningAddress.split("@");

  final name = parts.first;
  final domain = parts.last;
  return LNURL.encode("https://$domain/.well-known/lnurlp/$name");
}

String? lightningPaymentMemo(Payment payment) {
  final details = payment.details;
  if (details is! PaymentDetails_Lightning) {
    return null;
  }

  if (payment.paymentType == PaymentType.receive) {
    return details.lnurlReceiveMetadata?.senderComment;
  }

  final lnurlPayInfo = details.lnurlPayInfo;
  return lnurlPayInfo != null ? lnurlPayInfo.comment : details.description;
}
