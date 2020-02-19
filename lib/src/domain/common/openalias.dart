import 'package:basic_utils/basic_utils.dart';

String formatDomainName(String name) {
  if (!name.contains(".")) {
    return "";
  }

  return name.replaceAll("@", ".");
}

Future<String> fetchXmrAddress(String name) async {
  String xmrAddress = "";

  await DnsUtils.lookupRecord(name, RRecordType.TXT, dnssec: true).then((txtRecord) {
    if (txtRecord != null) {
      String record;

      for (int i = 0; i < txtRecord.length; i++) {
        record = txtRecord[i].data;

        if (record.contains("oa1:xmr") && record.contains("recipient_address")) {
          record = record.replaceAll('\"', "");
          xmrAddress = record.split(" ").where((item) => (item.contains("recipient_address")))
              .toString().replaceAll("recipient_address=", "").replaceAll("\;", "")
              .replaceAll("(", "").replaceAll(")", "");
          break;
        }
      }
    }
  });
  
  return xmrAddress;
}