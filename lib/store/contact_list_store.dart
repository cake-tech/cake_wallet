import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/contact_record.dart';

part 'contact_list_store.g.dart';

class ContactListStore = ContactListStoreBase with _$ContactListStore;

abstract class ContactListStoreBase with Store {
  ContactListStoreBase() : contacts = ObservableList<ContactRecord>();

  final ObservableList<ContactRecord> contacts;
}
