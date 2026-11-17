import "dart:convert";

import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/lnurl.dart";

String getLnurlOfLightningAddress(String lightningAddress) {
  final parts = lightningAddress.split("@");

  final name = parts.first;
  final domain = parts.last;
  return LNURL.encode("https://$domain/.well-known/lnurlp/$name");
}

void ensureCommentAccepted(String? comment, int commentAllowed) {
  if (comment != null && utf8.encode(comment).length > commentAllowed) {
    throw TransactionMemoNotAcceptedException(commentAllowed);
  }
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

final _commentInUrl = RegExp(r"(?<=[?&]comment=)[^&\s]*");
final _commentInDebugOutput = RegExp(r'(?<=comment"?: (?:Some|String)\(")(?:[^"\\]|\\.)*(?=")');

String redactPaymentComments(String logLine) =>
    logLine.replaceAll(_commentInUrl, "<redacted>").replaceAll(_commentInDebugOutput, "<redacted>");
