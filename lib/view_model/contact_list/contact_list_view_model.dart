import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/contact_service.dart';
import 'package:cake_wallet/store/contact_list_store.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(this.addressBookStore, this.contactService);

  final ContactListStore addressBookStore;
  final ContactService contactService;

  @computed
  ObservableList<Contact> get contacts => addressBookStore.contacts;

  Future<void> delete(Contact contact) async => contactService.delete(contact);
}