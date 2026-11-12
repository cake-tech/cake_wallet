import 'package:cake_wallet/core/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cw_core/crypto_currency.dart';

part 'contact_view_model.g.dart';

class ContactViewModel = ContactViewModelBase with _$ContactViewModel;

abstract class ContactViewModelBase with Store {
  ContactViewModelBase(this._contacts, this.appStore, this.adrResService, {ContactRecord? contact})
      : state = InitialExecutionState(),
        currencies = CryptoCurrency.all,
        _contact = contact,
        name = contact?.name ?? '',
        address = contact?.address ?? '',
        displayName = contact?.displayName ?? '',
        currency = contact?.type,
        lastChange = contact?.lastChange;

  final AppStore appStore;
  final AddressResolverService adrResService;

  @observable
  ExecutionState state;

  @observable
  String name;

  @observable
  String address;

  @observable
  String displayName;

  @observable
  CryptoCurrency? currency;

  @observable
  List<CryptoCurrency> currencies;

  ParsedAddress? _resolvedAddress;
  int _addressLookupGeneration = 0;

  int get addressLookupGeneration => _addressLookupGeneration;

  DateTime? lastChange;

  @computed
  bool get isReady {
    final selected = currency;
    final hasResolvedNamecoin = selected != null &&
        _resolvedAddress?.parsedAddressByCurrencyMap[selected] == address;
    final hasUsableAddress =
        !NamecoinRecord.isNamecoinIdentifier(address) || hasResolvedNamecoin;
    return name.isNotEmpty && selected != null && address.isNotEmpty && hasUsableAddress;
  }

  @computed
  bool get canAttemptSave =>
      isReady ||
      (name.isNotEmpty && address.isNotEmpty && NamecoinRecord.isNamecoinIdentifier(address));

  final Box<Contact> _contacts;
  final ContactRecord? _contact;

  @action
  void reset() {
    _addressLookupGeneration++;
    address = '';
    name = '';
    displayName = '';
    currency = null;
    currencies = CryptoCurrency.all;
    _resolvedAddress = null;
  }

  @action
  void updateAddress(String value) {
    if (value == address) return;

    _addressLookupGeneration++;
    address = value;
    displayName = '';
    _resolvedAddress = null;
    currencies = CryptoCurrency.all;
  }

  @action
  void selectCurrency(CryptoCurrency value) {
    if (!currencies.contains(value)) return;

    _addressLookupGeneration++;
    currency = value;
    final resolvedAddress = _resolvedAddress?.parsedAddressByCurrencyMap[value];
    if (resolvedAddress != null && resolvedAddress.isNotEmpty) address = resolvedAddress;
  }

  Future<ParsedAddress?> extractParsedAddress(BuildContext context) async {
    final wallet = appStore.wallet;
    final currentCurrency = currency;
    final query = address.trim();
    final generation = _addressLookupGeneration;

    if (wallet == null) return null;
    if (query.isEmpty) return null;

    // Check if the address is valid for the selected currency. With no selection,
    // resolution supplies the available currency choices instead.
    if (currentCurrency != null &&
        currentCurrency != CryptoCurrency.zano &&
        !NamecoinRecord.isNamecoinIdentifier(query)) {
      final isValidAddress = AddressValidator(type: currentCurrency).isValid(query);
      if (isValidAddress) return null;
    }

    final parsedAddresses = await adrResService.resolve(
      query: query,
      wallet: wallet,
      currency: currentCurrency,
    );

    if (!isAddressLookupCurrent(
      query: query,
      currency: currentCurrency,
      generation: generation,
    )) {
      return null;
    }

    if (parsedAddresses.isEmpty) return null;

    if (currentCurrency != null) {
      final resolvedAddress = parsedAddresses.first.parsedAddressByCurrencyMap[currentCurrency];
      if (resolvedAddress == null || resolvedAddress.isEmpty) return null;
    }

    return parsedAddresses.first;
  }

  bool isAddressLookupCurrent({
    required String query,
    required CryptoCurrency? currency,
    required int generation,
  }) =>
      generation == _addressLookupGeneration &&
      query == address.trim() &&
      currency == this.currency;

  @action
  void applyParsedAddress(ParsedAddress parsedAddress) {
    final addresses = parsedAddress.parsedAddressByCurrencyMap;
    final availableCurrencies = CryptoCurrency.all
        .where((item) => addresses[item]?.isNotEmpty ?? false)
        .toList(growable: false);
    if (availableCurrencies.isEmpty) return;

    _addressLookupGeneration++;
    _resolvedAddress = parsedAddress;
    currencies = availableCurrencies;
    displayName =
        parsedAddress.profileName.isNotEmpty ? parsedAddress.profileName : parsedAddress.handle;

    final selected = currency;
    if (selected != null) {
      if (addresses[selected]?.isNotEmpty == true) {
        address = addresses[selected]!;
      } else {
        // A selection made while the lookup was pending is explicit. Do not
        // substitute a sole alternative currency when that selection is absent.
        currency = null;
      }
    } else if (availableCurrencies.length == 1) {
      currency = availableCurrencies.single;
      address = addresses[currency]!;
    } else {
      // Keep the alias visible until the user chooses one of the currencies
      // actually present in the record. Never substitute another chain.
      currency = null;
    }
  }

  Future<void> save() async {
    try {
      state = IsExecutingState();
      final now = DateTime.now();

      final nameExists = _contact == null
          ? doesContactNameExist(name)
          : doesContactNameExist(name) && _contact.original.name != name;

      if (nameExists) {
        state = FailureState(S.current.contact_name_exists);
        return;
      }

      if (_contact != null && _contact.original.isInBox) {
        _contact.name = name;
        _contact.address = address;
        _contact.type = currency!;
        _contact.displayName = displayName;
        _contact.lastChange = now;
        await _contact.save();
      } else {
        await _contacts.add(Contact(
            name: name,
            address: address,
            type: currency!,
            lastChange: now,
            displayName: displayName));
      }

      lastChange = now;
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  bool doesContactNameExist(String name) {
    return _contacts.values.any((contact) => contact.name == name);
  }
}
