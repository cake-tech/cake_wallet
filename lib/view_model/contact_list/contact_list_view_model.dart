import 'dart:async';

import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

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
      if ([WalletType.monero, WalletType.wownero, WalletType.haven].contains(info.type) &&
          info.addressInfos != null) {
        for (var key in info.addressInfos!.keys) {
          final value = info.addressInfos![key];
          final address = value?.first;
          if (address != null) {
            final name = _createName(info.name, address.label, key: key);
            walletContacts.add(WalletContact(
              address.address,
              name,
              walletTypeToCryptoCurrency(info.type),
            ));
          }
        }
      } else if (info.addresses?.isNotEmpty == true && info.addresses!.length > 1) {
        if ([WalletType.monero, WalletType.wownero, WalletType.haven, WalletType.decred]
            .contains(info.type)) {
          final address = info.address;
          final name = _createName(info.name, "", key: 0);
          walletContacts.add(WalletContact(
            address,
            name,
            walletTypeToCryptoCurrency(info.type),
          ));
        } else {
          info.addresses!.forEach((address, label) {
            if (label.isEmpty) {
              return;
            }
            final name = _createName(info.name, label, key: null);
            walletContacts.add(WalletContact(
              address,
              name,
              walletTypeToCryptoCurrency(info.type,
                  isTestnet: info.network == null
                      ? false
                      : info.network!.toLowerCase().contains("testnet")),
            ));
          });
        }
      } else {
        walletContacts.add(WalletContact(
          info.address,
          _createName(info.name, "",
              key: [WalletType.monero, WalletType.wownero, WalletType.haven].contains(info.type)
                  ? 0
                  : null),
          walletTypeToCryptoCurrency(info.type),
        ));
      }
    });

    _subscription = contactSource.bindToListWithTransform(
        contacts, (Contact contact) => ContactRecord(contactSource, contact),
        initialFire: true);

    setOrderType(settingsStore.contactListOrder);
  }

  String _createName(String walletName, String label, {int? key = null}) {
    final actualLabel = label
        .replaceAll(RegExp(r'active', caseSensitive: false), S.current.active)
        .replaceAll(RegExp(r'silent payments', caseSensitive: false), S.current.silent_payments);
    return '$walletName${key == null ? "" : " [#${key}]"} ${actualLabel.isNotEmpty ? "($actualLabel)" : ""}'
        .trim();
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

  CryptoCurrency? get selectedCurrency => _currency;

  FilterListOrderType? get orderType => settingsStore.contactListOrder;

  bool get ascending => settingsStore.contactListAscending;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      settingsStore.shouldRequireTOTP2FAForAddingContacts;

  Future<void> delete(ContactRecord contact) async => contact.original.delete();

  ObservableList<ContactRecord> get contactsToShow => isEditable ? contacts :
      ObservableList.of(contacts.where((element) => _isContactValidForCurrency(element)));

  @computed
  List<WalletContact> get walletContactsToShow =>
      walletContacts.where((element) => _isValidForCurrency(element, true)).toList();

  bool _isValidForCurrency(ContactBase element, bool isWalletContact) {
    if (isEditable) return true;
    if (!element.name.contains('Active') &&
        isWalletContact &&
        (element.type == CryptoCurrency.btc || element.type == CryptoCurrency.ltc)) return false;

    return _isMatchToMainCurrency(element.type);
  }

  bool _isContactValidForCurrency(ContactRecord element) {

    final isAnyManualValid = element.original.manualAddresses.keys.any((raw) {
      final cur = CryptoCurrency.deserialize(raw: raw);
      return _isMatchToMainCurrency(cur);
    });

    if (isAnyManualValid) return true;

    final isAnyParsedValid = element.original.parsedByHandle.values.any((currencyMap) =>
        currencyMap.keys.any((raw) => _isMatchToMainCurrency(CryptoCurrency.deserialize(raw: raw))));

    return isAnyParsedValid;
  }

  bool _isMatchToMainCurrency (CryptoCurrency cur) =>
      _currency!= null &&  (cur == _currency ||
          (cur.tag != null && _currency.tag != null && cur.tag == _currency.tag) ||
          _currency.toString() == cur.tag ||
          _currency.tag == cur.toString());

  void dispose() => _subscription?.cancel();

  void saveCustomOrder() {
    final List<Contact> contactsSourceCopy = contacts.map((e) => e.original).toList();
    reorderContacts(contactsSourceCopy);
  }

  Future<void> saveCustomOrderFrom(Iterable<ContactRecord> ordered) async {
    final orderedContacts = ordered.map((e) => e.original).toList();
    await reorderContacts(orderedContacts);
    settingsStore.contactListOrder = FilterListOrderType.Custom;
  }

  void reorderAccordingToContactList() =>
      settingsStore.contactListOrder = FilterListOrderType.Custom;

  Future<void> reorderContacts(List<Contact> ordered) async {
    final mapByKey = { for (final c in contactSource.values) c.key: c };
    final keysInNewOrder = ordered.map((c) => c.key).toList();
    await contactSource.deleteAll(contactSource.keys);
    await contactSource.addAll(keysInNewOrder.map((k) => mapByKey[k]!));
  }


  Future<void> sortAlphabetically() async {
    final contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy.sort((a, b) {
      // Trim leading special characters and compare case-insensitively
      final keyA = a.name.trim().toLowerCase().replaceFirst(RegExp(r'^[^0-9A-Za-z]+'), '');
      final keyB = b.name.trim().toLowerCase().replaceFirst(RegExp(r'^[^0-9A-Za-z]+'), '');

      return ascending ? keyA.compareTo(keyB) : keyB.compareTo(keyA);
    });


    await reorderContacts(contactsSourceCopy);
  }

  Future<void> sortByCreationDate() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy.sort((a, b) =>
        ascending ? a.lastChange.compareTo(b.lastChange) : b.lastChange.compareTo(a.lastChange));

    await reorderContacts(contactsSourceCopy);
  }

  void setAscending(bool ascending) => settingsStore.contactListAscending = ascending;

  Future<void> setOrderType(FilterListOrderType? type) async {
    if (type == null) return;

    settingsStore.contactListOrder = type;

    switch (type) {
      case FilterListOrderType.CreationDate:
        await sortByCreationDate();
        break;
      case FilterListOrderType.Alphabetical:
        await sortAlphabetically();
        break;
      case FilterListOrderType.Custom:
      default:
        reorderAccordingToContactList();
        break;
    }
  }
}
