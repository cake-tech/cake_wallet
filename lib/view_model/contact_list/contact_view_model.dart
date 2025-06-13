import 'dart:io';

import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
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
  ContactViewModelBase(this._box, {ContactRecord? contact, required List<dynamic>? initialParams,})
      : state = InitialExecutionState(),
        currencies = CryptoCurrency.all,
        contactRecord = contact,
        name = contact?.name ?? '',
        handle = contact?.handle ?? '',
        profileName = contact?.profileName ?? '',
        description = contact?.description ?? '',
        imagePath = contact?.imagePath ?? '',
        sourceType = contact?.sourceType ?? AddressSource.notParsed,

        currency = (initialParams != null &&
            initialParams.isNotEmpty &&
            initialParams[0] is CryptoCurrency)
            ? initialParams[0] as CryptoCurrency
            : CryptoCurrency.xmr,

        initialCurrency = (initialParams != null &&
            initialParams.isNotEmpty &&
            initialParams[0] is CryptoCurrency)
            ? initialParams[0] as CryptoCurrency
            : null,
        manualLabel = (initialParams != null &&
            initialParams.length > 1 &&
            initialParams[1] is String)
            ? initialParams[1] as String
            : '',
        isNewAddress = !(initialParams != null &&
            initialParams.isNotEmpty &&
            initialParams[0] is CryptoCurrency) {

    const _emptyParsed = <CryptoCurrency, Map<String, String>>{};
    const _emptyManual = <CryptoCurrency, Map<String, String>>{};

    final parsedRaw = contact?.parsedAddresses ?? _emptyParsed;
    final manualRaw = contact?.manualAddresses ?? _emptyManual;

    parsedAddressesByCurrency = ObservableMap.of({
      for (final e in parsedRaw.entries)
        e.key: Map<String, String>.of(e.value)
    });

    manualAddressesByCurrency = ObservableMap.of({
      for (final e in manualRaw.entries)
        e.key: Map<String, String>.of(e.value)
    });
  }


  @observable
  ExecutionState state;
  @observable
  String name;
  @observable
  String handle;
  @observable
  String profileName;
  @observable
  String description;
  @observable
  String imagePath;
  @observable
  AddressSource sourceType;
  @observable
  CryptoCurrency currency;
  @observable
  String manualAddress = '';
  @observable
  String manualLabel = '';

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> parsedAddressesByCurrency = ObservableMap<
      CryptoCurrency,
      Map<String, String>>();

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> manualAddressesByCurrency = ObservableMap<
      CryptoCurrency,
      Map<String, String>>();

  final Box<Contact> _box;
  final ContactRecord? contactRecord;
  final List<CryptoCurrency> currencies;
  late final bool isNewAddress;
  CryptoCurrency? initialCurrency;

  @computed
  bool get isReady =>
      name
          .trim()
          .isNotEmpty && parsedAddressesByCurrency.isNotEmpty;

  ImageProvider get avatarProvider {
    final file = avatarFile;
    return (file != null && file.existsSync())
        ? FileImage(file)
        : const AssetImage('assets/images/profile.png');
  }

  @action
  void updateManualAddress() {
    if (manualAddress
        .trim()
        .isEmpty) return;

    final inner = manualAddressesByCurrency.putIfAbsent(currency, () => {});
    final base = manualLabel
        .trim()
        .isEmpty ? currency.title : manualLabel.trim();

    var label = base;
    var i = 1;
    while (inner.containsKey(label)) {
      label = '$base $i';
      i++;
    }

    inner[label] = manualAddress.trim();

    manualAddressesByCurrency[currency] = Map<String, String>.of(inner);
  }

  @action
  Future<void> pickAvatar(String localPath) async {
    imagePath = localPath;
  }

  void deleteManualAddress(CryptoCurrency cur, String label) {
    final inner = manualAddressesByCurrency[cur];
    if (inner == null) return;
    inner.remove(label);
    manualAddressesByCurrency[cur] = Map<String, String>.of(inner);
  }

  @action
  void reset() {
    name = '';
    handle = '';
    profileName = '';
    description = '';
    imagePath = '';
    parsedAddressesByCurrency.clear();
    manualAddressesByCurrency.clear();
  }

  Future<void> save() async {

    try {
      state = IsExecutingState();

      final clash = _box.values.any(
            (c) => c.name == name && c.key != contactRecord?.original.key,
      );
      if (clash) {
        state = FailureState(S.current.contact_name_exists);
        return;
      }

      if (contactRecord != null && contactRecord!.original.isInBox) {

        final contact = contactRecord!.original;

        contact
          ..name = name
          ..handle = handle
          ..profileName = profileName
          ..description = description
          ..imagePath = imagePath
          ..source = sourceType;

        contact.parsedAddresses
          ..clear()
          ..addAll({
            for (final e in parsedAddressesByCurrency.entries)
              e.key.raw: Map<String, String>.of(e.value)
          });

        contact.manualAddresses
          ..clear()
          ..addAll({
            for (final e in manualAddressesByCurrency.entries)
              e.key.raw: Map<String, String>.of(e.value)
          });

        await contact.save();


        contactRecord!
          ..parsedAddresses = ObservableMap.of(contact.parsedByCurrency)
          ..manualAddresses = ObservableMap.of(contact.manualByCurrency);
      } else {

        final newContact = Contact(
          name: name,
          parsedAddresses: {
            for (final e in parsedAddressesByCurrency.entries)
              e.key.raw: Map<String, String>.of(e.value)
          },
          manualAddresses: {
            for (final e in manualAddressesByCurrency.entries)
              e.key.raw: Map<String, String>.of(e.value)
          },
          source: sourceType,
          handle: handle,
          profileName: profileName,
          description: description,
          imagePath: imagePath,
          lastChange: DateTime.now(),
        );
        await _box.add(newContact);
      }
      state = ExecutedSuccessfullyState();
    } catch (e, st) {
      debugPrintStack(label: 'save() failed', stackTrace: st);
      state = FailureState(e.toString());
    }
  }

  File? get avatarFile => imagePath.isEmpty ? null : File(imagePath);
}
