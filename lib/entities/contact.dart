import 'dart:convert';

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
    this.address = '',
    CryptoCurrency? type,
    Map<String, Map<int, Map<String, String>>> parsedByHandle = const {},
    Map<int, Map<String, String>> manualAddresses = const {},
    Map<String, String> extraBlobs = const {},
    AddressSource source = AddressSource.notParsed,
    this.handle = '',
    this.imagePath = '',
    this.profileName = '',
    this.description = '',
    DateTime? lastChange,
  })  : raw = type?.raw ?? 0,
        _parsedJson = _encode(parsedByHandle),
        _manualJson = _encode(manualAddresses),
        extraJsonBlobs = extraBlobs,
        sourceRaw = source.raw,
        lastChange = lastChange ?? DateTime.now();

  factory Contact.fromParsed(ParsedAddress p,
      {String? localImage, Map<CryptoCurrency, String>? customLabels}) {
    final manual = <int, Map<String, String>>{};
    p.manualAddressByCurrencyMap?.forEach((cur, addr) {
      final lbl = customLabels?[cur] ?? cur.title;
      manual[cur.raw] = {lbl: addr};
    });

    final parsed = <String, Map<int, Map<String, String>>>{};
    if (p.parsedAddressByCurrencyMap.isNotEmpty) {
      final hKey = '${p.addressSource.label}-${p.handle}';
      parsed[hKey] = {
        for (final e in p.parsedAddressByCurrencyMap.entries) e.key.raw: {e.key.title: e.value}
      };
    }

    return Contact(
      name: p.profileName.isNotEmpty ? p.profileName : p.handle,
      profileName: p.profileName,
      handle: p.handle,
      description: p.description,
      source: p.addressSource,
      imagePath: localImage ?? '',
      manualAddresses: manual,
      parsedByHandle: parsed,
    );
  }

  static const typeId = CONTACT_TYPE_ID;
  static const boxName = 'Contacts';

  @HiveField(0, defaultValue: '')
  String name;

  @HiveField(1, defaultValue: '')
  String address;

  @HiveField(2, defaultValue: 0)
  int raw;

  @HiveField(3)
  DateTime lastChange;

  @HiveField(4, defaultValue: '')
  String _parsedJson;

  @HiveField(5, defaultValue: '')
  String _manualJson;

  @HiveField(6, defaultValue: '')
  String handle;

  @HiveField(7, defaultValue: '')
  String imagePath;

  @HiveField(8, defaultValue: '')
  String profileName;

  @HiveField(9, defaultValue: '')
  String description;

  @HiveField(10, defaultValue: 0)
  int sourceRaw;

  @HiveField(11, defaultValue: {})
  Map<String, String> extraJsonBlobs;

  AddressSource get source => AddressSourceIndex.fromRaw(sourceRaw);

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw);

  Map<String, Map<int, Map<String, String>>> get parsedByHandle => _decodeParsed(_parsedJson);

  Map<int, Map<String, String>> get manualAddresses => _decodeManual(_manualJson);

  Map<CryptoCurrency, Map<String, String>> get manualByCurrency =>
      manualAddresses.map((k, v) => MapEntry(CryptoCurrency.deserialize(raw: k), v));



  set source(AddressSource v) => sourceRaw = v.raw;

  set type(CryptoCurrency v) => raw = v.raw;

  set parsedByHandle(Map<String, Map<int, Map<String, String>>> v) => _parsedJson = _encode(v);

  set manualAddresses(Map<int, Map<String, String>> v) => _manualJson = _encode(v);

  @override
  dynamic get keyIndex => key;

  @override
  bool operator ==(Object o) => o is Contact && o.key == key;

  @override
  int get hashCode => key.hashCode;

  static String _encode(Object value) => jsonEncode(_stringifyKeys(value));

  static dynamic _stringifyKeys(dynamic obj) {
    if (obj is Map) {
      return obj.map(
        (k, v) => MapEntry(k.toString(), _stringifyKeys(v)),
      );
    }
    if (obj is Iterable) return obj.map(_stringifyKeys).toList();
    return obj;
  }

  static Map<String, Map<int, Map<String, String>>> _decodeParsed(String s) {
    if (s.isEmpty) return {};
    final Map<String, dynamic> data = jsonDecode(s) as Map<String, dynamic>;
    return data.map((handle, byCur) {
      final inner = (byCur as Map<String, dynamic>).map((curRaw, lblMap) {
        final int cur = int.parse(curRaw);
        final labels = (lblMap as Map).cast<String, String>();
        return MapEntry(cur, labels);
      });
      return MapEntry(handle, inner);
    });
  }

  static Map<int, Map<String, String>> _decodeManual(String s) {
    if (s.isEmpty) return {};
    final Map<String, dynamic> data = jsonDecode(s) as Map<String, dynamic>;
    return data.map((curRaw, lblMap) {
      final int cur = int.parse(curRaw);
      final labels = (lblMap as Map).cast<String, String>();
      return MapEntry(cur, labels);
    });
  }

}
