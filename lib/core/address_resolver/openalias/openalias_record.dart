import 'package:basic_utils/basic_utils.dart';
import 'package:cw_core/utils/print_verbose.dart';

class OpenaliasRecord {
  OpenaliasRecord({
    required this.address,
    required this.name,
    required this.description,
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

  static Future<List<RRecord>?> lookupOpenAliasRecord(String name) async {
    try {
      final txtRecord = await DnsUtils.lookupRecord(name, RRecordType.TXT, dnssec: true);

      return txtRecord;
    } catch (e) {
      printV("${e.toString()}");
      return null;
    }
  }

  static OpenaliasRecord fetchAddressAndName({
    required String formattedName,
    required String ticker,
    required List<RRecord> txtRecord,
  }) {
    var address = '';
    var name = formattedName;
    var note = '';

    final addrRe = RegExp(r'recipient_address=([^;\s]+)', caseSensitive: false);
    final nameRe = RegExp(r'recipient_name=([^;]+)', caseSensitive: false);
    final noteRe = RegExp(r'tx_description=([^;]+)', caseSensitive: false);
    final tag = 'oa1:$ticker';

    for (final rr in txtRecord) {
      final txt = rr.data.replaceAll('"', '');

      if (!txt.toLowerCase().contains(tag)) continue;

      final addrM = addrRe.firstMatch(txt);
      if (addrM != null) address = addrM.group(1)!;

      final nameM = nameRe.firstMatch(txt);
      if (nameM != null) name = nameM.group(1)!.trim();

      final noteM = noteRe.firstMatch(txt);
      if (noteM != null) note = noteM.group(1)!.trim();

      break;
    }

    return OpenaliasRecord(address: address, name: name, description: note);
  }
}
