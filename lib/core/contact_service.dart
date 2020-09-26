import 'package:hive/hive.dart';
import 'package:cake_wallet/store/contact_list_store.dart';
import 'package:cake_wallet/entities/contact.dart';

class ContactService {
  ContactService(this.contactSource, this.contactListStore) {
    _forceUpdateContactListStore();
  }

  final Box<Contact> contactSource;
  final ContactListStore contactListStore;

  Future add(Contact contact) async {
    await contactSource.add(contact);
    // contactListStore.contacts.add(contact);
  }

  Future update(Contact contact) async {
    await contact.save();
    final index = contactListStore.contacts.indexOf(contact) ?? -1;

    if (index >= 0) {
      _forceUpdateContactListStore();
    } else {
      // contactListStore.contacts.add(contact);
    }
  }

  Future delete(Contact contact) async {
    await contact.delete();
    contactListStore.contacts.remove(contact);
  }

  void _forceUpdateContactListStore() {
    contactListStore.contacts.clear();
    // contactListStore.contacts.addAll(contactSource.values);
  }
}
