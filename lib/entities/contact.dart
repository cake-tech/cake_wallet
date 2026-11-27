import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/keyable.dart";
import "package:sqflite/sqflite.dart";

class Contact with Keyable {
  Contact({
    required this.name,
    required this.address,
    this.id = 0,
    CryptoCurrency? type,
    int? currencyRaw,
    DateTime? lastChange,
    this.displayName = "",
    this.sortOrder = 0,
  }) : assert(type != null || currencyRaw != null, "Contact needs a currency"),
       currencyRaw = currencyRaw ?? type!.raw,
       lastChange = lastChange ?? DateTime.now();

  int id;
  String name;
  String address;
  int currencyRaw;
  DateTime lastChange;
  String displayName;
  int sortOrder;

  static String get tableName => "Contact";

  static String get selfIdColumn => "contactId";

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: currencyRaw);

  bool get isSaved => id != 0;

  @override
  dynamic get keyIndex => id;

  @override
  bool operator ==(Object other) =>
      other is Contact && (isSaved ? other.id == id : identical(other, this));

  @override
  int get hashCode => id.hashCode;

  void updateCryptoCurrency({required CryptoCurrency currency}) => currencyRaw = currency.raw;

  Map<String, dynamic> toJson() => {
    selfIdColumn: id,
    "name": name,
    "address": address,
    "currencyRaw": currencyRaw,
    "lastChange": lastChange.millisecondsSinceEpoch,
    "displayName": displayName,
    "sortOrder": sortOrder,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json[selfIdColumn] as int,
    name: json["name"] as String? ?? "",
    address: json["address"] as String? ?? "",
    // NOT NULL without defaults: a missing value is a bug, not XMR / 1970.
    currencyRaw: json["currencyRaw"] as int,
    lastChange: DateTime.fromMillisecondsSinceEpoch(json["lastChange"] as int),
    displayName: json["displayName"] as String? ?? "",
    sortOrder: json["sortOrder"] as int? ?? 0,
  );

  Future<int> save() async {
    final json = toJson();
    if (json[selfIdColumn] == 0) {
      json[selfIdColumn] = null;
    }
    id = await db!.insert(tableName, json, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<int> delete(Contact contact) async {
    if (!contact.isSaved) return 0;
    return await db!.delete(tableName, where: "$selfIdColumn = ?", whereArgs: [contact.id]);
  }

  static Future<void> updateOrder(List<Contact> contacts) async {
    await db!.transaction((txn) async {
      for (var i = 0; i < contacts.length; i++) {
        contacts[i].sortOrder = i;
        await txn.update(
          tableName,
          {"sortOrder": i},
          where: "$selfIdColumn = ?",
          whereArgs: [contacts[i].id],
        );
      }
    });
  }

  static Future<List<Contact>> selectList(
    String where,
    List<dynamic> whereArgs, {
    String orderBy = "sortOrder",
  }) async {
    final query = await db!.query(
      tableName,
      where: where.isNotEmpty ? where : "1 = 1",
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );
    return query
        .map(Contact.fromJson)
        .where((c) => CryptoCurrency.safeDeserialize(raw: c.currencyRaw) != null)
        .toList();
  }

  static Future<List<Contact>> getAll() => selectList("", []);

  static Future<Contact?> get(int id) async {
    final list = await selectList("$selfIdColumn = ?", [id]);
    return list.isEmpty ? null : list.first;
  }

  static Future<List<Contact>> getByAddress(String address) => selectList("address = ?", [address]);

  static Future<List<Contact>> getByCurrency(CryptoCurrency currency) =>
      selectList("currencyRaw = ?", [currency.raw]);
}
