import 'dart:io';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/src/screens/address_book/entities/address_edit_request.dart';
import 'package:cake_wallet/src/screens/address_book/entities/user_handles.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'contact_view_model.g.dart';

typedef ValidatorType = String? Function(String? raw);

enum ContactEditMode {
  contactInfo,
  manualAddress,
  parsedAddress,
}

class ContactViewModel = _ContactViewModel with _$ContactViewModel;

abstract class _ContactViewModel with Store {
  _ContactViewModel(
    this.box,
    this.wallet,
    this.settingsStore, {
    AddressEditRequest? request,
  })  : mode = request?.mode == EditMode.manualAddressAdd ||
                request?.mode == EditMode.manualAddressEdit
            ? ContactEditMode.manualAddress
            : request?.mode == EditMode.parsedAddressAdd ||
                    request?.mode == EditMode.parsedAddressEdit
                ? ContactEditMode.parsedAddress
                : ContactEditMode.contactInfo,
        record = request?.contact,
        currencies = CryptoCurrency.all,
        state = InitialExecutionState(),
        name = request?.contact?.name ?? '',
        handle = request?.contact?.handle ?? '',
        profileName = request?.contact?.profileName ?? '',
        description = request?.contact?.description ?? '',
        imagePath = request?.contact?.imagePath ?? '',
        sourceType = request?.contact?.sourceType ?? AddressSource.notParsed,
        currency = request?.currency,
        label = request?.label ?? '',
        address = '',
        handleKey = request?.handleKey ?? '' {
    _initMapsFromRecord();

    if (request?.label != null && record != null) {
      currency = request!.currency!;
      label = request.label!;
      address = _targetMap[currency]?[label] ?? '';
    }
  }

  final Box<Contact> box;
  final WalletBase wallet;
  final SettingsStore? settingsStore;
  final ContactEditMode mode;
  final List<CryptoCurrency> currencies;
  ContactRecord? record;

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
  CryptoCurrency? currency;

  @observable
  String label;

  @observable
  String address;

  @observable
  String handleKey;

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> manual = ObservableMap();

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> parsed = ObservableMap();

  @observable
  ObservableMap<String, Map<CryptoCurrency, Map<String, String>>> parsedBlocks = ObservableMap();

  @computed
  ImageProvider get avatar => imagePath.isEmpty
      ? const AssetImage('assets/images/profile.png')
      : FileImage(File(imagePath));

  ObservableMap<CryptoCurrency, Map<String, String>> get _targetMap =>
      mode == ContactEditMode.manualAddress
          ? manual
          : parsed[currency] != null
              ? parsed
              : manual;

  @action
  Future<void> refresh() async {
    state = IsExecutingState();
    final resolver = getIt<AddressResolverService>();

    final originalBlocks = Map<String, Map<CryptoCurrency, Map<String, String>>>.from(parsedBlocks);

    try {
      for (final entry in originalBlocks.entries) {
        final handleKey = entry.key;
        final sourceLabel = handleKey.split('-').first;
        final handle = handleKey.substring(sourceLabel.length + 1);

        final newResults = await resolver.resolve(
          query: handle,
          wallet: wallet,
        );

        final Map<CryptoCurrency, Map<String, String>> refreshed = {};

        for (final parsed in newResults) {
          parsed.parsedAddressByCurrencyMap.forEach((cur, addr) {
            final oldLabel = parsedBlocks[handleKey]?[cur]?.keys.firstOrNull ?? cur.title;

            (refreshed[cur] ??= {})[oldLabel] = addr;
          });
        }

        parsedBlocks[handleKey] = refreshed;
        record?.replaceParsedBlock(handleKey, refreshed);
      }
    } catch (e) {
      state = FailureState(e.toString());
      return;
    }

    await record?.original.save();
    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> saveContactInfo() async {
    if (record != null) {
      record!
        ..name = name.trim()
        ..handle = handle.trim()
        ..profileName = profileName.trim()
        ..description = description.trim()
        ..imagePath = imagePath
        ..sourceType = sourceType;
      record!.original..lastChange = DateTime.now();
      await record!.original.save();
      state = ExecutedSuccessfullyState();
      return;
    }
    final newContact = Contact(
      name: name.trim(),
      address: '',
    )
      ..handle = handle.trim()
      ..profileName = profileName.trim()
      ..description = description.trim()
      ..imagePath = imagePath
      ..source = sourceType
      ..lastChange = DateTime.now();

    await box.put(newContact.key, newContact);
    record = ContactRecord(box, newContact);
  }

  @action
  Future<void> saveManualAddress({
    required CryptoCurrency oldCurrency,
    required CryptoCurrency selectedCurrency,
    required String oldLabel,
    required String newLabel,
    required String newAddress
  }) async {
    if (record == null) return;

    final oldMap = manual[oldCurrency];
    if (oldMap == null || !oldMap.containsKey(oldLabel)) return;

    final trimmed = newAddress.trim();

    oldMap.remove(oldLabel);
    if (oldMap.isEmpty) {
      manual.remove(oldCurrency);
      record!.removeManualAddress(oldCurrency, oldLabel);
    } else {
      manual[oldCurrency] = Map.of(oldMap);
      record!.removeManualAddress(oldCurrency, oldLabel);
    }

    final newMap = manual.putIfAbsent(selectedCurrency, () => {});
    newMap[newLabel] = trimmed;
    manual[selectedCurrency] = Map.of(newMap);
    record!.setManualAddress(selectedCurrency, newLabel, trimmed);
  }

  @action
  Future<void> deleteManualAddress(
      {required CryptoCurrency currency, required String label}) async {
    if (record == null) return;
    final map = manual[currency];
    if (map == null || !map.containsKey(label)) return;

    map.remove(label);
    if (map.isEmpty) {
      manual.remove(currency);
    } else {
      manual[currency] = Map.of(map);
    }

    record!.removeManualAddress(currency, label);
  }

  @action
  Future<void> deleteParsedBlock(String handleKey) async {
    if (!parsedBlocks.containsKey(handleKey)) return;

    parsedBlocks.remove(handleKey);
    record!.removeParsedAddress(handleKey, null, null);
  }

  @action
  Future<void> deleteContact() async {
    if (record == null) return;

    await record!.original.delete();
    record = null;
    reset();
  }

  @action
  void reset() {
    name = handle = profileName = description = imagePath = '';
    label = address = handleKey = '';
    currency = CryptoCurrency.xmr;
    manual.clear();
    parsed.clear();
    parsedBlocks.clear();
    state = InitialExecutionState();
  }

  void _initMapsFromRecord() {
    if (record == null) return;

    manual = ObservableMap.of(record!.manual);
    parsed = ObservableMap.of(record!.parsedByCurrency);
    parsedBlocks = ObservableMap.of(record!.parsedBlocks);
  }

  ValidatorType get contactNameValidator => (String? name) {
        final value = name?.trim() ?? '';

        if (value.isEmpty) return 'Name cannot be empty';
        if (value.length > 30) return 'Name is too long';

        final currentKey = record?.original.key;
        final exists = box.values.any(
          (c) => c.name.toLowerCase() == value.toLowerCase() && c.key != currentKey,
        );
        return exists ? 'Contact with this name already exists' : null;
      };

  ValidatorType get manualAddressLabelValidator => (String? label) {
        final value = label?.trim() ?? '';

        if (value.isEmpty) return 'Label cannot be empty';
        if (value.length > 30) return 'Label is too long';
        if (manual[currency] == null || manual[currency]!.isEmpty) return null;
        final exists =
            manual[currency]?.keys.any((l) => l.toLowerCase() == value.toLowerCase()) ?? false;
        return exists ? 'Label already exists for this currency' : null;
      };

  late final Map<String, (bool Function(), void Function(bool))> lookupMap = settingsStore != null
      ? {
          AddressSource.twitter.label: (
            () => settingsStore!.lookupsTwitter,
            (v) => settingsStore!.lookupsTwitter = v
          ),
          AddressSource.zanoAlias.label: (
            () => settingsStore!.lookupsZanoAlias,
            (v) => settingsStore!.lookupsZanoAlias = v
          ),
          AddressSource.mastodon.label: (
            () => settingsStore!.lookupsMastodon,
            (v) => settingsStore!.lookupsMastodon = v
          ),
          AddressSource.yatRecord.label: (
            () => settingsStore!.lookupsYatService,
            (v) => settingsStore!.lookupsYatService = v
          ),
          AddressSource.unstoppableDomains.label: (
            () => settingsStore!.lookupsUnstoppableDomains,
            (v) => settingsStore!.lookupsUnstoppableDomains = v
          ),
          AddressSource.openAlias.label: (
            () => settingsStore!.lookupsOpenAlias,
            (v) => settingsStore!.lookupsOpenAlias = v
          ),
          AddressSource.ens.label: (
            () => settingsStore!.lookupsENS,
            (v) => settingsStore!.lookupsENS = v
          ),
          AddressSource.wellKnown.label: (
            () => settingsStore!.lookupsWellKnown,
            (v) => settingsStore!.lookupsWellKnown = v
          ),
          AddressSource.fio.label: (
            () => settingsStore!.lookupsFio,
            (v) => settingsStore!.lookupsFio = v
          ),
          AddressSource.nostr.label: (
            () => settingsStore!.lookupsNostr,
            (v) => settingsStore!.lookupsNostr = v
          ),
          AddressSource.thorChain.label: (
            () => settingsStore!.lookupsThorChain,
            (v) => settingsStore!.lookupsThorChain = v
          ),
          AddressSource.bip353.label: (
            () => settingsStore!.lookupsBip353,
            (v) => settingsStore!.lookupsBip353 = v
          ),
        }
      : {};
}
