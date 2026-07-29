import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/contact_record.dart";
import "package:cw_core/crypto_currency.dart";
import "package:mobx/mobx.dart";

class ContactService {
  ContactService();

  final ObservableList<ContactRecord> contacts = ObservableList<ContactRecord>();

  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() => _loaded ? Future<void>.value() : reload();


  Future<void> reload() {
    final loading = _loading;
    if (loading != null) return loading;

    final future = _load();
    _loading = future;
    return future.whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final all = await Contact.getAll();

    contacts
      ..clear()
      ..addAll(all.map(ContactRecord.new));

    _loaded = true;
  }

  Future<ContactRecord> add({
    required String name,
    required String address,
    required CryptoCurrency type,
    String displayName = "",
  }) async {
    final record = ContactRecord(Contact(
      name: name,
      address: address,
      type: type,
      displayName: displayName,
      sortOrder: contacts.length,
    ));

    await record.save();
    contacts.add(record);

    return record;
  }

  Future<void> update(ContactRecord record) async {
    await record.save();

    if (!contacts.contains(record)) {
      contacts.add(record);
    }
  }

  Future<void> delete(ContactRecord record) async {
    await record.delete();
    contacts.remove(record);
  }

  void applyOrder(List<Contact> ordered) {
    final byId = {for (final record in contacts) record.original.id: record};
    final reordered = ordered.map((c) => byId[c.id]).whereType<ContactRecord>().toList();

    if (reordered.length != contacts.length) return;

    contacts
      ..clear()
      ..addAll(reordered);
  }
}
