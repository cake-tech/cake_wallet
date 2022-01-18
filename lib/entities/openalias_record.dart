import 'package:basic_utils/basic_utils.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class OpenaliasRecord {
  OpenaliasRecord({
    this.address,
    this.name,
    this.description,
  });

  final String name;
  final String address;
  final String description;

  static String formatDomainName(String name) {
    String formattedName = name;

    if (name.contains("@")) {
      formattedName = name.replaceAll("@", ".");
    }

    return formattedName;
  }

  static Future<OpenaliasRecord> fetchAddressAndName({
    @required String formattedName,
    @required String ticker,
  }) async {
    String address = formattedName;
    String name = formattedName;
    String note = '';

    if (formattedName.contains(".")) {
      try {
        final txtRecord = await DnsUtils.lookupRecord(
            formattedName, RRecordType.TXT,
            dnssec: true);

        if (txtRecord != null) {
          for (RRecord element in txtRecord) {
            String record = element.data;

            if (record.contains("oa1:$ticker") &&
                record.contains("recipient_address")) {
              record = record.replaceAll('\"', "");

              final dataList = record.split(";");

              address = dataList
                  .where((item) => (item.contains("recipient_address")))
                  .toString()
                  .replaceAll("oa1:$ticker recipient_address=", "")
                  .replaceAll("(", "")
                  .replaceAll(")", "")
                  .trim();

              final recipientName = dataList
                  .where((item) => (item.contains("recipient_name")))
                  .toString()
                  .replaceAll("(", "")
                  .replaceAll(")", "")
                  .trim();

              if (recipientName.isNotEmpty) {
                name = recipientName.replaceAll("recipient_name=", "");
              }

              final description = dataList
                  .where((item) => (item.contains("tx_description")))
                  .toString()
                  .replaceAll("(", "")
                  .replaceAll(")", "")
                  .trim();

              if (description.isNotEmpty) {
                note = description.replaceAll("tx_description=", "");
              }

              break;
            }
          }
        }
      } catch (e) {
        print("${e.toString()}");
      }
    }

    return OpenaliasRecord(address: address, name: name, description: note);
  }
}
