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
    updateList();

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

  @action
  void updateList() {
    contacts.clear();
    contacts.addAll(contactSource.values.map((contact) => ContactRecord(contactSource, contact)));
  }

  Future<void> reorderAccordingToContactList() async {
    settingsStore.contactListOrder = WalletListOrderType.Custom;

    Map<dynamic, Contact> contactSourceCopy = Map.fromIterable(contactSource.values,
        key: (item) => item.key, value: (item) => item as Contact);

    List<MapEntry<dynamic, Contact>> newOrder = [];

    for (ContactRecord contactRecord in contacts) {

      var foundEntry = contactSourceCopy.entries.firstWhereOrNull(
            (entry) => entry.value.name == contactRecord.name,
      );
      if (foundEntry != null) {
        newOrder.add(foundEntry);
        contactSourceCopy.remove(foundEntry.key);
      }
    }
    await contactSource.clear();

    for (var entry in newOrder) {
      await contactSource.put(entry.key, entry.value);
    }
  }

  Future<void> sortGroupByType() async {
    Map<dynamic, Contact> contactSourceCopy = Map.fromIterable(contactSource.values,
        key: (item) => item.key, value: (item) => item as Contact);

    var entries = contactSourceCopy.entries.toList();

    entries.sort((a, b) =>
    ascending ? a.value.type.toString().compareTo(b.value.type.toString()) : b.value.name.compareTo(a.value.type.toString()));

    await contactSource.clear();

    for (var entry in entries) {

      await contactSource.put(entry.key, entry.value);
    }
  }

  Future<void> sortAlphabetically() async {
    Map<dynamic, Contact> contactSourceCopy = Map.fromIterable(contactSource.values,
        key: (item) => item.key, value: (item) => item as Contact);

    var entries = contactSourceCopy.entries.toList();

    entries.sort((a, b) =>
        ascending ? a.value.name.compareTo(b.value.name) : b.value.name.compareTo(a.value.name));

    await contactSource.clear();

    for (var entry in entries) {
      await contactSource.put(entry.key, entry.value);
    }
  }

  Future<void> sortByCreationDate() async {
    Map<dynamic, Contact> contactSourceCopy = Map.fromIterable(contactSource.values,
        key: (item) => item.key, value: (item) => item as Contact);

    var entries = contactSourceCopy.entries.toList();
    entries.sort((a, b) => ascending
        ? a.value.lastChange.compareTo(b.value.lastChange)
        : b.value.lastChange.compareTo(a.value.lastChange));

    await contactSource.clear();

    for (var entry in entries) {
      await contactSource.put(entry.key, entry.value);
    }
  }

  void setAscending(bool ascending) {
    settingsStore.contactListAscending = ascending;
  }

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
        await reorderAccordingToContactList();
        break;
    }
  }

  Future<List<int>> loadContactOrder() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? stringOrder = prefs.getStringList(PreferencesKey.customContactListOrder);
    if (stringOrder != null) {
      return stringOrder.map((i) => int.parse(i)).toList();
    } else {
      return <int>[];
    }
  }

  Future<void> saveContactOrder(List<int> order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stringOrder = order.map((i) => i.toString()).toList();
    await prefs.setStringList( PreferencesKey.customContactListOrder, stringOrder);
  }

  @action
  Future<void> applyOrderToContacts() async {
    List<int> order = await loadContactOrder();
    if (order.isEmpty) return;
    if (order.length != contacts.length) return;

    contacts.clear();
    for (var key in order) {
      var contact = contactSource.get(key);
      if (contact != null) {
        contacts.add(ContactRecord(contactSource, contact));
      }
    }
  }
}
