import "package:cake_wallet/entities/contact.dart" as sqlite;
import "package:cw_core/cake_hive.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/hive_type_ids.dart";
import "package:cw_core/keyable.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:hive/hive.dart";

part "contact_legacy.part.dart";

Future<void> performContactHiveMigration() async {
  try {
    if (!CakeHive.isAdapterRegistered(Contact.typeId)) {
      CakeHive.registerAdapter(ContactAdapter());
    }

    final box = await CakeHive.openBox<Contact>(Contact.boxName);
    await Contact.migrateAllToSqlite(box);
    await box.deleteFromDisk();
  } catch (e) {
    printV("Error migrating contacts to sqlite: $e, continuing anyway");
  }
}

// @HiveType(typeId: Contact.typeId)
class Contact extends HiveObject with Keyable {
  Contact(
      {required this.name,
        required this.address,
        CryptoCurrency? type,
        DateTime? lastChange,
        this.displayName = "",})
      : lastChange = lastChange ?? DateTime.now() {
    if (type != null) {
      raw = type.raw;
    }
  }

  static const typeId = CONTACT_TYPE_ID;
  static const boxName = "Contacts";

  // @HiveField(0, defaultValue: '')
  String name;

  // @HiveField(1, defaultValue: '')
  String address;

  // @HiveField(2, defaultValue: 0)
  late int raw;

  // @HiveField(3)
  DateTime lastChange;

  // @HiveField(4, defaultValue: "")
  String displayName;

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw);

  @override
  dynamic get keyIndex => key;

  @override
  bool operator ==(Object o) => o is Contact && o.key == key;

  @override
  int get hashCode => key.hashCode;

  void updateCryptoCurrency({required CryptoCurrency currency}) => raw = currency.raw;

  static Future<void> migrateAllToSqlite(Box<Contact> box) async {
    final contacts = box.values.toList();

    if (contacts.isEmpty) return;

    await db!.transaction((txn) async {
      for (var i = 0; i < contacts.length; i++) {
        final contact = contacts[i];

        final json = sqlite.Contact(
          name: contact.name,
          address: contact.address,
          raw: contact.raw,
          lastChange: contact.lastChange,
          displayName: contact.displayName,
          // Box iteration order was the user's custom order — preserve it.
          sortOrder: i,
        ).toJson()
          ..remove(sqlite.Contact.selfIdColumn);

        await txn.insert(sqlite.Contact.tableName, json);
      }
    });

    await box.clear();
  }
}