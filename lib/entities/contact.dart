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
    int? raw,
    DateTime? lastChange,
    this.displayName = "",
    this.sortOrder = 0,
  })  : raw = raw ?? type?.raw ?? 0,
        lastChange = lastChange ?? DateTime.now();

  int id;
  String name;
  String address;
  int raw;
  DateTime lastChange;
  String displayName;
  int sortOrder;

  static String get tableName => "Contact";

  static String get selfIdColumn => "contactId";

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw);

  bool get isSaved => id != 0;

  @override
  dynamic get keyIndex => id;

  @override
  bool operator ==(Object other) => other is Contact && (isSaved ? other.id == id : identical(other, this));

  @override
  int get hashCode => id.hashCode;

  void updateCryptoCurrency({required CryptoCurrency currency}) => raw = currency.raw;

  Map<String, dynamic> toJson() => {
        selfIdColumn: id,
        "name": name,
        "address": address,
        "raw": raw,
        "lastChange": lastChange.millisecondsSinceEpoch,
        "displayName": displayName,
        "sortOrder": sortOrder,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json[selfIdColumn] as int,
        name: json["name"] as String? ?? "",
        address: json["address"] as String? ?? "",
        raw: json["raw"] as int? ?? 0,
        lastChange: DateTime.fromMillisecondsSinceEpoch(json["lastChange"] as int? ?? 0),
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
        await txn.update(tableName, {"sortOrder": i},
            where: "$selfIdColumn = ?", whereArgs: [contacts[i].id]);
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
    return List.generate(query.length, (index) => Contact.fromJson(query[index]));
  }

  static Future<List<Contact>> getAll() => selectList("", []);

  static Future<Contact?> get(int id) async {
    final list = await selectList("$selfIdColumn = ?", [id]);
    return list.isEmpty ? null : list.first;
  }

  static Future<List<Contact>> getByAddress(String address) => selectList("address = ?", [address]);

  static Future<List<Contact>> getByCurrency(CryptoCurrency currency) =>
      selectList("raw = ?", [currency.raw]);
}
