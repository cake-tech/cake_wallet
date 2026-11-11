import 'dart:async';

import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/new-ui/entries/address_book/wallet_contact_utils.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/evm/evm.dart';
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_loader.dart";
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/utils/print_verbose.dart";
import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'contact_list_view_model.g.dart';

class ContactListViewModel = ContactListViewModelBase with _$ContactListViewModel;

abstract class ContactListViewModelBase with Store {
  ContactListViewModelBase(
      this.contactSource, List<WalletInfo> wallets, this._currency, this.settingsStore)
      : contacts = ObservableList<ContactRecord>(),
        isAutoGenerateEnabled =
            settingsStore.autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.enabled {
    unawaited(_init());
  }

  Future<void> _init() async {
    await loadWalletContacts();

    _subscription = contactSource.bindToListWithTransform(
      contacts,
      (contact) => ContactRecord(contactSource, contact),
      initialFire: true,
    );

    setOrderType(settingsStore.contactListOrder);
  }

  Future<void> _lastWalletContactsLoad = Future.value();

  /// Kept for Send/Exchange/NFT (internal-wallet and 2FA checks, which only compare addresses).
  /// The Address Book reads wallet contacts from `WalletContactsCubit`.
  @action
  Future<void> loadWalletContacts() async {
    final waitFor = _lastWalletContactsLoad;
    final done = Completer<void>();
    _lastWalletContactsLoad = done.future;

    await waitFor;

    try {
      final loadedContacts = <WalletContact>[];
      for (final info in await WalletInfo.getAll()) {
        loadedContacts.addAll(await loadWalletContactsForWallet(info, groupId: info.groupId));
      }

      walletContacts = loadedContacts;
    } catch (e) {
      printV("loadWalletContacts failed: $e");
    } finally {
      done.complete();
    }
  }

  final bool isAutoGenerateEnabled;
  final Box<Contact> contactSource;
  final ObservableList<ContactRecord> contacts;
  @observable
  List<WalletContact> walletContacts = [];
  final CryptoCurrency? _currency;
  StreamSubscription<BoxEvent>? _subscription;
  final SettingsStore settingsStore;

  bool get isEditable => _currency == null;

  FilterListOrderType? get orderType => settingsStore.contactListOrder;

  bool get ascending => settingsStore.contactListAscending;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      settingsStore.shouldRequireTOTP2FAForAddingContacts;

  Future<void> delete(ContactRecord contact) async => contact.original.delete();

  ObservableList<ContactRecord> get contactsToShow =>
      ObservableList.of(contacts.where((element) => _isValidForCurrency(element, false)));

  @computed
  List<WalletContact> get walletContactsToShow =>
      walletContacts.where((element) => _isValidForCurrency(element, true)).toList();

  bool _isValidForCurrency(ContactBase element, bool isWalletContact) =>
      isContactValidForCurrency(element, _currency,
          isWalletContact: isWalletContact, chainIdForWalletType: evm?.getChainIdByWalletType);

  void dispose() => _subscription?.cancel();

  void saveCustomOrder() {
    final List<Contact> contactsSourceCopy = contacts.map((e) => e.original).toList();
    reorderContacts(contactsSourceCopy);
  }

  void reorderAccordingToContactList() =>
      settingsStore.contactListOrder = FilterListOrderType.Custom;

  Future<void> reorderContacts(List<Contact> contactCopy) async {
    await contactSource.deleteAll(contactCopy.map((e) => e.key).toList());
    await contactSource.addAll(contactCopy);
  }

  Future<void> sortGroupByType() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy.sort((a, b) => ascending
        ? a.type.toString().compareTo(b.type.toString())
        : b.type.toString().compareTo(a.type.toString()));

    await reorderContacts(contactsSourceCopy);
  }

  Future<void> sortAlphabetically() async {
    List<Contact> contactsSourceCopy = contactSource.values.toList();

    contactsSourceCopy
        .sort((a, b) => ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

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
      case FilterListOrderType.GroupByType:
        await sortGroupByType();
        break;
      case FilterListOrderType.Custom:
        reorderAccordingToContactList();
        break;
    }
  }
}
