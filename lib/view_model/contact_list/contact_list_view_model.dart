import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase
    with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(this.contactSource)
      : contacts = ObservableList<ContactRecord>() {
    _subscription = contactSource.bindToListWithTransform(
        contacts, (Contact contact) => ContactRecord(contactSource, contact),
        initialFire: true);
  }

  final Box<Contact> contactSource;
  final ObservableList<ContactRecord> contacts;
  StreamSubscription<BoxEvent> _subscription;

  Future<void> delete(ContactRecord contact) async => contact.original.delete();
}
