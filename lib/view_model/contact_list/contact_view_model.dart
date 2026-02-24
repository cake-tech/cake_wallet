import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cake_wallet/src/screens/send/widgets/extract_address_from_parsed.dart';
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
  ContactViewModelBase(this._contacts,  {ContactRecord? contact})
      : state = InitialExecutionState(),
        currencies = CryptoCurrency.all,
        _contact = contact,
        name = contact?.name ?? '',
        address = contact?.address ?? '',
        displayName = contact?.displayName ?? '',
        currency = contact?.type,
        lastChange = contact?.lastChange;


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
      name.isNotEmpty &&
      (currency?.toString().isNotEmpty ?? false) &&
      address.isNotEmpty;

  final List<CryptoCurrency> currencies;
  final Box<Contact> _contacts;
  final ContactRecord? _contact;

  @action
  void reset() {
    address = '';
    name = '';
    currency = null;
  }

  Future<void> extractParsedAddress(BuildContext context) async{
    if(currency == null) return;
    final parsedAddress = await getIt.get<AddressResolver>().resolve(context, address, currency!);
    if(parsedAddress.name.isNotEmpty) {
      displayName = parsedAddress.name;
    }
    address = await extractAddressFromParsed(context, parsedAddress);
    printV(displayName);
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
        await _contacts
            .add(Contact(name: name, address: address, type: currency!, lastChange: now, displayName: displayName));
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