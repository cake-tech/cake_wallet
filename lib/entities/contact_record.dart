import "package:cake_wallet/entities/contact.dart";
import "package:cake_wallet/entities/contact_base.dart";
import "package:cw_core/crypto_currency.dart";
import "package:mobx/mobx.dart";

part "contact_record.g.dart";

class ContactRecord = ContactRecordBase with _$ContactRecord;

abstract class ContactRecordBase with Store implements ContactBase {
  ContactRecordBase(this.original)
      : name = original.name,
        address = original.address,
        type = original.type,
        displayName = original.displayName,
        lastChange = original.lastChange;

  final Contact original;

  @override
  @observable
  String name;

  @override
  @observable
  String address;

  @override
  @observable
  CryptoCurrency type;

  @override
  @observable
  String displayName;

  @observable
  DateTime? lastChange;

  int get id => original.id;

  bool get isSaved => original.isSaved;

  /// Saves the local edits to the model and persists it to the database.
  @action
  Future<void> save() async {
    original.name = name;
    original.address = address;
    original.displayName = displayName;
    original.updateCryptoCurrency(currency: type);
    original.lastChange = lastChange ?? DateTime.now();

    await original.save();

    lastChange = original.lastChange;
  }

  Future<void> delete() => Contact.delete(original);

  /// Discards local edits and re-reads the values from the model.
  @action
  void revert() {
    name = original.name;
    address = original.address;
    type = original.type;
    displayName = original.displayName;
    lastChange = original.lastChange;
  }
}
