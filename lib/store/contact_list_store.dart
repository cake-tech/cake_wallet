import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';

part 'contact_list_store.g.dart';

class ContactListStore = ContactListStoreBase with _$ContactListStore;

abstract class ContactListStoreBase with Store {
  ContactListStoreBase() : contacts = ObservableList<Contact>();

  final ObservableList<Contact> contacts;
}
