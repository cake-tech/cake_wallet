import 'package:basic_utils/basic_utils.dart';

String formatDomainName(String name) {
  String formattedName = name;

  if (name.contains(".")) {
    formattedName = name.replaceAll("@", ".");
  }

  return formattedName;
}

Future<Map<String, String>> fetchXmrAddressAndRecipientName(String name) async {
  final map = {"recipient_address" : name, "recipient_name" : name};

  await DnsUtils.lookupRecord(name, RRecordType.TXT, dnssec: true).then((txtRecord) {
    if (txtRecord != null) {
      String record;

      for (int i = 0; i < txtRecord.length; i++) {
        record = txtRecord[i].data;

        if (record.contains("oa1:xmr") && record.contains("recipient_address")) {
          record = record.replaceAll('\"', "");

          final dataList = record.split(";");

          map["recipient_address"] = dataList.where((item) => (item.contains("recipient_address")))
              .toString().replaceAll("oa1:xmr recipient_address=", "")
              .replaceAll("(", "").replaceAll(")", "").trim();

          final recipientName = dataList.where((item) => (item.contains("recipient_name"))).toString();

          if (recipientName.isNotEmpty) {
            map["recipient_name"] = recipientName.replaceAll("recipient_name=", "")
                .replaceAll("(", "").replaceAll(")", "").trim();
          }

          break;
        }
      }
    }
  });
  
  return map;
}