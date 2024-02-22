import 'dart:async';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(
      this.contactSource, this.walletInfoSource, this._currency, this.settingsStore)
      : contacts = ObservableList<ContactRecord>(),
        walletContacts = [],
        isAutoGenerateEnabled =
            settingsStore.autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.enabled {
    walletInfoSource.values.forEach((info) {
      if (isAutoGenerateEnabled && info.type == WalletType.monero && info.addressInfos != null) {
        info.addressInfos!.forEach((key, value) {
          final nextUnusedAddress = value.firstWhereOrNull(
              (addressInfo) => !(info.usedAddresses?.contains(addressInfo.address) ?? false));
          if (nextUnusedAddress != null) {
            final name = _createName(info.name, nextUnusedAddress.label);
            walletContacts.add(WalletContact(
              nextUnusedAddress.address,
              name,
              walletTypeToCryptoCurrency(info.type),
            ));
          }
        });
      } else if (info.addresses?.isNotEmpty == true) {
        info.addresses!.forEach((address, label) {
          final name = _createName(info.name, label);
          walletContacts.add(WalletContact(
            address,
            name,
            walletTypeToCryptoCurrency(info.type),
          ));
        });
      } else if (info.address != null) {
        walletContacts.add(WalletContact(
          info.address,
          info.name,
          walletTypeToCryptoCurrency(info.type),
        ));
      }
    });

    _subscription = contactSource.bindToListWithTransform(
        contacts, (Contact contact) => ContactRecord(contactSource, contact),
        initialFire: true);

    setOrderType(settingsStore.contactListOrder);
  }

  String _createName(String walletName, String label) {
    return label.isNotEmpty ? '$walletName ($label)' : walletName;
  }

  final bool isAutoGenerateEnabled;
  final Box<Contact> contactSource;
  final Box<WalletInfo> walletInfoSource;
  final ObservableList<ContactRecord> contacts;
  final List<WalletContact> walletContacts;
  final CryptoCurrency? _currency;
  StreamSubscription<BoxEvent>? _subscription;
  final SettingsStore settingsStore;

  bool get isEditable => _currency == null;

  WalletListOrderType? get orderType => settingsStore.contactListOrder;

  bool get ascending => settingsStore.contactListAscending;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      settingsStore.shouldRequireTOTP2FAForAddingContacts;

  Future<void> delete(ContactRecord contact) async => contact.original.delete();

  @computed
  List<ContactRecord> get contactsToShow =>
      contacts.where((element) => _isValidForCurrency(element)).toList();

  @computed
  List<WalletContact> get walletContactsToShow =>
      walletContacts.where((element) => _isValidForCurrency(element)).toList();

  bool _isValidForCurrency(ContactBase element) {
    return _currency == null ||
        element.type == _currency ||
        element.type.title == _currency!.tag ||
        element.type.tag == _currency!.tag;
  }

  void dispose() async {
    _subscription?.cancel();
    final List<Contact> contactsSourceCopy = contactSource.values.toList();
    reorderContacts(contactsSourceCopy);
  }

  void reorderAccordingToContactList() =>
      settingsStore.contactListOrder = WalletListOrderType.Custom;

  Future<void> reorderContacts(List<Contact> contactCopy) async {
    await contactSource.deleteAll(contactCopy.map((e) => e.key).toList());
    await contactSource.addAll(contactCopy);
  }

  Future<void> sortGroupByType() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy.sort((a, b) => ascending
        ? a.type.toString().compareTo(b.type.toString())
        : b.type.toString().compareTo(a.type.toString()));

    reorderContacts(contactsSourceCopy);
  }

  Future<void> sortAlphabetically() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy
        .sort((a, b) => ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    reorderContacts(contactsSourceCopy);
  }

  Future<void> sortByCreationDate() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy.sort((a, b) =>
        ascending ? a.lastChange.compareTo(b.lastChange) : b.lastChange.compareTo(a.lastChange));

    reorderContacts(contactsSourceCopy);
  }

  void setAscending(bool ascending) => settingsStore.contactListAscending = ascending;

  Future<void> setOrderType(WalletListOrderType? type) async {
    if (type == null) return;

    settingsStore.contactListOrder = type;

    switch (type) {
      case WalletListOrderType.CreationDate:
        await sortByCreationDate();
        break;
      case WalletListOrderType.Alphabetical:
        await sortAlphabetically();
        break;
      case WalletListOrderType.GroupByType:
        await sortGroupByType();
        break;
      case WalletListOrderType.Custom:
      default:
        reorderAccordingToContactList();
        break;
    }
  }
}
