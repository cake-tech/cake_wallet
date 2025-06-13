import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: Contact.typeId)
class Contact extends HiveObject with Keyable {
  Contact({
    required this.name,
    required this.parsedAddresses,
    required this.manualAddresses,
    AddressSource source = AddressSource.notParsed,
    this.handle = '',
    this.imagePath = '',
    this.profileName = '',
    this.description = '',
    DateTime? lastChange,
  })  : sourceRaw = source.raw,
        lastChange = lastChange ?? DateTime.now();

  static const typeId = CONTACT_TYPE_ID;
  static const boxName = 'Contacts';

  factory Contact.fromParsed(ParsedAddress p, {String? localImage}) {
    return Contact(
      name: p.profileName.isNotEmpty ? p.profileName : p.handle,
      profileName: p.profileName,
      handle: p.handle,
      description: p.description,
      source: p.addressSource,
      imagePath: localImage ?? '',
      parsedAddresses: {
        if (p.parsedAddressByCurrencyMap.isNotEmpty)
        for (final e in p.parsedAddressByCurrencyMap.entries) e.key.raw: {e.key.title: e.value}
      },
      manualAddresses: {
        if (p.manualAddressByCurrencyMap != null && p.manualAddressByCurrencyMap!.isNotEmpty)
        for (final e in p.manualAddressByCurrencyMap!.entries) e.key.raw: {e.key.title: e.value}
      },
    );
  }



  @HiveField(0, defaultValue: '')
  String name;

  @HiveField(1, defaultValue: {})
  Map<int, Map<String, String>> parsedAddresses;

  @HiveField(2, defaultValue: 0)
  int sourceRaw;

  @HiveField(3, defaultValue: '')
  String handle;

  @HiveField(4, defaultValue: '')
  String imagePath;

  @HiveField(5, defaultValue: '')
  String profileName;

  @HiveField(6, defaultValue: '')
  String description;

  @HiveField(7)
  DateTime lastChange;

  @HiveField(8, defaultValue: {})
  Map<int, Map<String, String>> manualAddresses;

  void setAddress(
      {required CryptoCurrency currency,
      required String label,
      required String address,
      bool isManual = false}) {
    final target = isManual ? manualAddresses : parsedAddresses;

    target.putIfAbsent(currency.raw, () => <String, String>{});
    final inner = target[currency.raw]!;

    final baseLabel = (label.trim().isEmpty ? currency.title : label).trim();
    final uniqueLabel = _getUniqueLabel(baseLabel, inner);

    inner[uniqueLabel] = address;
    lastChange = DateTime.now();
    save();
  }

  Map<CryptoCurrency, Map<String, String>> get parsedByCurrency =>
      parsedAddresses.map((k, v) => MapEntry(CryptoCurrency.deserialize(raw: k), v));

  Map<CryptoCurrency, Map<String, String>> get manualByCurrency =>
      manualAddresses.map((k, v) => MapEntry(CryptoCurrency.deserialize(raw: k), v));

  AddressSource get source => AddressSourceIndex.fromRaw(sourceRaw);

  set source(AddressSource source) => sourceRaw = source.raw;

  @override
  dynamic get keyIndex => key;

  String _getUniqueLabel(String base, Map<String, String> byLabel) {
    if (!byLabel.containsKey(base)) return base;

    var i = 1;
    while (byLabel.containsKey('$base $i')) i++;
    return base + '_' + '$i';
  }

  @override
  bool operator ==(Object other) => other is Contact && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
