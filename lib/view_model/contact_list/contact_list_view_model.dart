import 'dart:async';

import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/wallet_contact.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
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
              walletTypeToCryptoCurrency(
                info.type,
                chainId: info.type == WalletType.evm ? 1 : null,
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
            walletTypeToCryptoCurrency(
              info.type,
              chainId: info.type == WalletType.evm ? 1 : null,
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
              walletTypeToCryptoCurrency(
                info.type,
                isTestnet:
                    info.network == null ? false : info.network!.toLowerCase().contains("testnet"),
                chainId: info.type == WalletType.evm ? 1 : null,
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
          walletTypeToCryptoCurrency(
            info.type,
            chainId: info.type == WalletType.evm ? 1 : null,
          ),
          walletType: info.type,
        ));
      }
    }

    _subscription = contactSource.bindToListWithTransform(
        contacts, (Contact contact) => ContactRecord(contactSource, contact),
        initialFire: true);

    setOrderType(settingsStore.contactListOrder);
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

  bool _isValidForCurrency(ContactBase element, bool isWalletContact) {
    if (_currency == null) return true;
    if (!element.name.contains('Active') &&
        isWalletContact &&
        (element.type == CryptoCurrency.btc || element.type == CryptoCurrency.ltc)) return false;

    // Check for exact currency match
    if (element.type == _currency) return true;

    // Check for tag matching
    if (element.type.tag != null && _currency.tag != null && element.type.tag == _currency.tag) {
      return true;
    }

    if (_currency.toString() == element.type.tag || _currency.tag == element.type.toString()) {
      return true;
    }

    // For EVM wallet contacts: use walletType field for proper filtering
    if (isWalletContact && element is WalletContact) {
      final contactWalletType = element.walletType;
      if (contactWalletType == null) {
        // If wallet type is not available, use currency-based check
        if (_isEVMCompatibleCurrency(_currency) && _isEVMCompatibleCurrency(element.type)) {
          return true;
        }
        return false;
      }

      if (!_isEVMCompatibleCurrency(_currency)) {
        return false;
      }

      final currentWalletType = _getWalletTypeFromCurrency(_currency);

      // For WalletType.evm: show all EVM-compatible wallet contacts
      // If we can't determine the wallet type from currency, assume it's WalletType.evm
      if (currentWalletType == null || currentWalletType == WalletType.evm) {
        return isEVMCompatibleChain(contactWalletType);
      }

      // For old individual EVM types (ethereum, polygon, base, arbitrum):
      // Show wallets that match that wallet type, plus WalletType.evm wallets
      if (isEVMCompatibleChain(currentWalletType)) {
        if (contactWalletType == currentWalletType) {
          return true;
        }
        // Also show WalletType.evm wallets (they can switch to any chain including this one)
        if (contactWalletType == WalletType.evm) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get wallet type from currency (for EVM currencies)
  /// Returns null if currency doesn't correspond to a specific old wallet type
  /// (null means it could be WalletType.evm or we can't determine)
  WalletType? _getWalletTypeFromCurrency(CryptoCurrency currency) {
    // ERC20 tokens don't have a specific wallet type - they could be from any EVM chain
    if (currency is Erc20Token) {
      return null;
    }

    // Check for native EVM currencies with tags that indicate old wallet types
    final tag = currency.tag?.toUpperCase();

    // Currencies with tags (POL, BASE, ARB) indicate old wallet types
    if (tag == 'POL') {
      return WalletType.polygon;
    }
    if (tag == 'BASE') {
      return WalletType.base;
    }
    if (tag == 'ARB') {
      return WalletType.arbitrum;
    }

    // ETH without a tag could be either WalletType.ethereum or WalletType.evm
    // We can't determine, so return null (will be treated as WalletType.evm)
    if (currency == CryptoCurrency.eth) {
      return null; // Could be WalletType.ethereum or WalletType.evm
    }

    // MATIC/Polygon currencies
    if (currency == CryptoCurrency.maticpoly || currency == CryptoCurrency.matic) {
      return WalletType.polygon;
    }

    // Try to get chainId from currency, then get wallet type
    final title = currency.title.toLowerCase();
    int? chainId;
    if (tag != null) {
      chainId = evm!.getChainIdByTag(tag);
    }
    if (chainId == null) {
      chainId = evm!.getChainIdByTitle(title);
    }

    if (chainId != null) {
      // Get wallet type from chainId
      final walletType = evm!.getWalletTypeByChainId(chainId);
      // Only return old wallet types, not WalletType.evm
      if (walletType != null && walletType != WalletType.evm) {
        return walletType;
      }
    }

    return null;
  }

  /// Check if a currency is EVM-compatible (ERC20 token or native EVM currency)
  bool _isEVMCompatibleCurrency(CryptoCurrency currency) {
    // ERC20 tokens are always EVM-compatible
    if (currency is Erc20Token) return true;

    // Check for native EVM currencies
    // These are currencies that correspond to EVM chains
    final title = currency.title.toLowerCase();
    final tag = currency.tag?.toUpperCase();

    // Native EVM currencies
    return title == 'eth' ||
        title == 'ethereum' ||
        title == 'matic' ||
        title == 'polygon' ||
        title == 'base' ||
        title == 'arbitrum' ||
        tag == 'ETH' ||
        tag == 'POL' ||
        tag == 'BASE' ||
        tag == 'ARB' ||
        currency == CryptoCurrency.eth ||
        currency == CryptoCurrency.maticpoly ||
        currency == CryptoCurrency.matic;
  }

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
