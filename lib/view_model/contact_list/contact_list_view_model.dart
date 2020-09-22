import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/contact_service.dart';
import 'package:cake_wallet/store/contact_list_store.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/utils/mobx.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase
    with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(
      this.addressBookStore, this.contactService, this.contactSource) {
    _subscription = bindBox(contactSource, addressBookStore.contacts);
  }

  final ContactListStore addressBookStore;
  final ContactService contactService;
  final Box<Contact> contactSource;

  ObservableList<Contact> get contacts => addressBookStore.contacts;

  StreamSubscription<BoxEvent> _subscription;

  void dispose() {
    _subscription.cancel();
  }

  Future<void> delete(Contact contact) async => contactService.delete(contact);
}
