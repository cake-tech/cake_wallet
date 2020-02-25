import 'package:basic_utils/basic_utils.dart';

class OpenaliasRecord {

  OpenaliasRecord({this.name});

  String name;
  String address;

  String get recordName => name;
  String get recordAddress => address;

  String formatDomainName() {
    String formattedName = name;

    if (name.contains("@")) {
      formattedName = name.replaceAll("@", ".");
    }

    return formattedName;
  }

  Future<void> fetchAddressAndName(String name) async {
    this.name = name;
    address =  name;

    try {
      final txtRecord = await DnsUtils.lookupRecord(name, RRecordType.TXT, dnssec: true);

      if (txtRecord != null) {

        for (RRecord element in txtRecord) {
          String record = element.data;

          if (record.contains("oa1:xmr") && record.contains("recipient_address")) {
            record = record.replaceAll('\"', "");

            final dataList = record.split(";");

            address = dataList.where((item) => (item.contains("recipient_address")))
                .toString().replaceAll("oa1:xmr recipient_address=", "")
                .replaceAll("(", "").replaceAll(")", "").trim();

            final recipientName = dataList.where((item) => (item.contains("recipient_name"))).toString()
                .replaceAll("(", "").replaceAll(")", "").trim();

            if (recipientName.isNotEmpty) {
              this.name = recipientName.replaceAll("recipient_name=", "");
            }

            break;
          }
        }
      }
    } catch (e) {
      print("${e.toString()}");
    }
  }

}

