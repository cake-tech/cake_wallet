import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/contact_record.dart";
import "package:cw_core/crypto_currency.dart";
import "package:mobx/mobx.dart";

class ContactService {
  ContactService();

  final ObservableList<ContactRecord> contacts = ObservableList<ContactRecord>();

  Future<void>? _loading;
  bool _loaded = false;
  int _generation = 0;

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() => _loading ??= _load();

  void invalidate() {
    _generation++;
    _loading = null;
    _loaded = false;
    contacts.clear();
  }

  Future<void> _load() async {
    final generation = _generation;
    try {
      final all = await Contact.getAll();
      if (generation != _generation) return;
      contacts
        ..clear()
        ..addAll(all.map(ContactRecord.new));
      _loaded = true;
    } catch (_) {
      if (generation == _generation) _loading = null;
      rethrow;
    }
  }

  Future<ContactRecord> add({
    required String name,
    required String address,
    required CryptoCurrency type,
    String displayName = "",
  }) async {
    await ensureLoaded();
    final record = ContactRecord(
      Contact(
        name: name,
        address: address,
        type: type,
        displayName: displayName,
        sortOrder: contacts.length,
      ),
    );

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

  Future<void> reorder(List<Contact> ordered) async {
    await Contact.updateOrder(ordered);

    final positions = {for (final c in ordered) c.id: c.sortOrder};
    for (final record in contacts) {
      final position = positions[record.original.id];
      if (position != null) record.original.sortOrder = position;
    }

    contacts.sort((a, b) => a.original.sortOrder.compareTo(b.original.sortOrder));
  }
}
