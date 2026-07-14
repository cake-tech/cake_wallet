import 'package:cake_wallet/core/address_resolver/address_resolver_service.dart';
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

  DateTime? lastChange;

  @computed
  bool get isReady =>
      name.isNotEmpty && (currency?.toString().isNotEmpty ?? false) && address.isNotEmpty;

  final List<CryptoCurrency> currencies;
  final Box<Contact> _contacts;
  final ContactRecord? _contact;

  @action
  void reset() {
    address = '';
    name = '';
    displayName = '';
    currency = null;
  }

  Future<ParsedAddress?> extractParsedAddress(BuildContext context) async {
    final wallet = appStore.wallet;
    final currentCurrency = currency;
    final query = address.trim();

    if (wallet == null) return null;
    if (currentCurrency == null) return null;
    if (query.isEmpty) return null;

    // Check if the address is valid for the current currency (except for Zano, which can use handles as addresses)
    if (currentCurrency != CryptoCurrency.zano) {
      final isValidAddress = AddressValidator(type: currentCurrency).isValid(query);
      if (isValidAddress) return null;
    }

    final parsedAddresses = await adrResService.resolve(
      query: query,
      wallet: wallet,
      currency: currentCurrency,
    );

    if (parsedAddresses.isEmpty) return null;

    final resolvedAddress = parsedAddresses.first.parsedAddressByCurrencyMap[currentCurrency];
    if (resolvedAddress == null || resolvedAddress.isEmpty) return null;

    return parsedAddresses.first;
  }

  @action
  void applyParsedAddress(ParsedAddress parsedAddress) {
    final currentCurrency = currency;
    if (currentCurrency == null) return;

    final resolvedAddress = parsedAddress.parsedAddressByCurrencyMap[currentCurrency];
    if (resolvedAddress == null || resolvedAddress.isEmpty) return;

    address = resolvedAddress;
    displayName =
        parsedAddress.profileName.isNotEmpty ? parsedAddress.profileName : parsedAddress.handle;
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
