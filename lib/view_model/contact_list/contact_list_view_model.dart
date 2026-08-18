import 'dart:async';

import "package:cake_wallet/core/contact_service.dart";
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/token_utilities.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(
      this.contactService, this._currency, this.settingsStore,)
      : isAutoGenerateEnabled =
      settingsStore.autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.enabled {
    unawaited(_init());
  }

  Future<void> _init() async {
    final walletInfos = await WalletInfo.getAll();
    for (final info in walletInfos) {
      final addressInfos = await info.getAddressInfos();
      final addresses = await info.getAddresses();
      if ([WalletType.monero, WalletType.wownero, WalletType.haven].contains(info.type) &&
          addressInfos.isNotEmpty) {
        for (var key in addressInfos.keys) {
          final value = addressInfos[key];
          final address = value?.first;
          if (address != null) {
            final name = _createName(info.name, address.label, key: key);
            walletContacts.add(WalletContact(
              address.address,
              name,
              getCryptoCurrencyForWalletListItem(
                info.type,
              ),
              walletType: info.type,
            ));
          }
        }
      } else if (addresses.isNotEmpty == true && addresses.length > 1) {
        if ([WalletType.monero, WalletType.wownero, WalletType.haven, WalletType.decred]
            .contains(info.type)) {
          final address = info.address;
          final name = _createName(info.name, "", key: 0);
          walletContacts.add(WalletContact(
            address,
            name,
            getCryptoCurrencyForWalletListItem(
              info.type,
            ),
            walletType: info.type,
          ));
        } else {
          addresses.forEach((address, label) {
            if (label.isEmpty) {
              return;
            }
            final name = _createName(info.name, label, key: null);
            walletContacts.add(WalletContact(
              address,
              name,
              getCryptoCurrencyForWalletListItem(
                info.type,
                isTestnet:
                    info.network == null ? false : info.network!.toLowerCase().contains("testnet"),
              ),
              walletType: info.type,
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
          getCryptoCurrencyForWalletListItem(
            info.type,
          ),
          walletType: info.type,
        ));
      }
    }


    // Load contacts from the database
    await contactService.ensureLoaded();

    await setOrderType(settingsStore.contactListOrder);
    walletContacts = walletContacts.toList(); // rebuild
  }

  String _createName(String walletName, String label, {int? key = null}) {
    final actualLabel = label
        .replaceAll(RegExp(r'active', caseSensitive: false), S.current.active)
        .replaceAll(RegExp(r'silent payments', caseSensitive: false), S.current.silent_payments);
    return '$walletName${key == null ? "" : " [#${key}]"} ${actualLabel.isNotEmpty ? "($actualLabel)" : ""}'
        .trim();
  }

  final bool isAutoGenerateEnabled;
  final ContactService contactService;

  ObservableList<ContactRecord> get contacts => contactService.contacts;

  @observable
  List<WalletContact> walletContacts = [];
  final CryptoCurrency? _currency;
  final SettingsStore settingsStore;

  bool get isEditable => _currency == null;

  FilterListOrderType? get orderType => settingsStore.contactListOrder;

  bool get ascending => settingsStore.contactListAscending;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      settingsStore.shouldRequireTOTP2FAForAddingContacts;

  Future<void> delete(ContactRecord contact) => contactService.delete(contact);

  ObservableList<ContactRecord> get contactsToShow =>
      ObservableList.of(contacts.where((element) => _isValidForCurrency(element, false)));

  @computed
  List<WalletContact> get walletContactsToShow =>
      walletContacts.where((element) => _isValidForCurrency(element, true)).toList();

  bool _isValidForCurrency(ContactBase element, bool isWalletContact) {
    if (_currency == null) return true;
    if (!element.name.contains('Active') &&
        isWalletContact &&
        (element.type == CryptoCurrency.btc || element.type == CryptoCurrency.ltc)) return false;

    final currencyMatches = element.type == _currency;

    final tagsMatch =
        element.type.tag != null && _currency.tag != null && element.type.tag == _currency.tag;

    final tagMatchesTitle = _currency.tag != null && _currency.tag == element.type.title;

    final titleMatchesTag = _currency.title == element.type.tag;

    var matches = currencyMatches || tagsMatch || tagMatchesTitle || titleMatchesTag;

    if (matches && isWalletContact && element is WalletContact && element.walletType != null) {
      final walletType = element.walletType!;

      if (isEVMCompatibleChain(walletType)) {
        final currencyChainId = TokenUtilities.getChainId(_currency);
        final walletChainId = evm!.getChainIdByWalletType(walletType);

        if (currencyChainId != walletChainId) matches = false;
      }
    }

    return matches;
  }

  Future<void> saveCustomOrder() => reorderContacts(contacts.map((e) => e.original).toList());

  Future<void> reorderAccordingToContactList() async {
    settingsStore.contactListOrder = FilterListOrderType.Custom;
    await reorderContacts(contacts.map((e) => e.original).toList());
  }


  Future<void> reorderContacts(List<Contact> contactCopy) async {
    await Contact.updateOrder(contactCopy);
    contactService.applyOrder(contactCopy);
  }

  Future<void> sortGroupByType() async {
    final contactsSourceCopy = contacts.map((e) => e.original).toList();

    contactsSourceCopy.sort((a, b) => ascending
        ? a.type.toString().compareTo(b.type.toString())
        : b.type.toString().compareTo(a.type.toString()));

    await reorderContacts(contactsSourceCopy);
  }

  Future<void> sortAlphabetically() async {
    final contactsSourceCopy = contacts.map((e) => e.original).toList();

    contactsSourceCopy
        .sort((a, b) => ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    await reorderContacts(contactsSourceCopy);
  }

  Future<void> sortByCreationDate() async {
    final contactsSourceCopy = contacts.map((e) => e.original).toList();

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
      case FilterListOrderType.GroupByType:
        await sortGroupByType();
        break;
      case FilterListOrderType.Custom:
        await reorderAccordingToContactList();
        break;
    }
  }
}
