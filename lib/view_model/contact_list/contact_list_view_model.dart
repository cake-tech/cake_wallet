import 'dart:async';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/crypto_currency.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase
    with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(this.contactSource, this.walletInfoSource)
      : contacts = ObservableList<ContactRecord>(),
        walletContacts = [] {
    walletInfoSource.values.forEach((info) {
      if (info.addresses?.isNotEmpty ?? false) {
        info.addresses?.forEach((address, label) {
          final name = label.isNotEmpty
            ? info.name + ' ($label)'
            : info.name;

          walletContacts.add(WalletContact(
              address,
              name,
              walletTypeToCryptoCurrency(info.type)));
        });
      }
    });

    _subscription = contactSource.bindToListWithTransform(
        contacts, (Contact contact) => ContactRecord(contactSource, contact),
        initialFire: true);
  }

  final Box<Contact> contactSource;
  final Box<WalletInfo> walletInfoSource;
  final ObservableList<ContactRecord> contacts;
  final List<WalletContact> walletContacts;
  StreamSubscription<BoxEvent>? _subscription;

  Future<void> delete(ContactRecord contact) async => contact.original.delete();

  List<ContactRecord> getContacts(bool isEditable, CryptoCurrency? cur) {
    if (!isEditable) {
      return contacts.where((element) => element.type == cur).toList();
    }

    return contacts;
  }

  List<WalletContact> getWallets(bool isEditable, CryptoCurrency? cur) {
    if (!isEditable) {
      return walletContacts.where((element) => element.type == cur).toList();
    }

    return walletContacts;
  }
}
