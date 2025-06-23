import 'dart:io';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/src/screens/address_book/entities/address_edit_request.dart';
import 'package:cake_wallet/src/screens/address_book/entities/user_handles.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'contact_view_model.g.dart';

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
        currency = request?.currency ?? CryptoCurrency.xmr,
        label = request?.label ?? '',
        address = '',
        handleKey = request?.handleKey ?? '' {
    _initMapsFromRecord();

    if (request?.label != null && record != null) {
      currency = request!.currency!;
      label = request.label!;
      address = _targetMap[currency]?[label] ?? '';

      _rememberOriginal(
        blockKey: mode == ContactEditMode.parsedAddress
            ? (request.handleKey ?? _defaultHandleKey())
            : null,
      );
    }
  }

  final Box<Contact> box;
  final WalletBase wallet;
  final SettingsStore? settingsStore;
  ContactRecord? record;

  @observable
  ExecutionState state;

  @observable
  String name, handle, profileName, description, imagePath;
  @observable
  AddressSource sourceType;

  @observable
  CryptoCurrency currency;
  @observable
  String label, address, handleKey;

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> manual = ObservableMap();
  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> parsed = ObservableMap();
  @observable
  ObservableMap<String, Map<CryptoCurrency, Map<String, String>>> parsedBlocks = ObservableMap();

  final ContactEditMode mode;
  final List<CryptoCurrency> currencies;

  CryptoCurrency? _originalCur;
  String? _originalLabel, _originalAddress, _originalHandleKey;

  @computed
  bool get isReady => name.trim().isNotEmpty || manual.isNotEmpty || parsed.isNotEmpty;

  @computed
  List<UserHandles> get userHandles =>
      parsedBlocks.keys.map((k) => UserHandles(handleKey: k)).toList();

  @computed
  ImageProvider get avatar => imagePath.isEmpty
      ? const AssetImage('assets/images/profile.png')
      : FileImage(File(imagePath));

  bool get isAddressEdit =>
      mode != ContactEditMode.contactInfo && record != null && (_originalLabel ?? '').isNotEmpty;

  ObservableMap<CryptoCurrency, Map<String, String>> get _targetMap =>
      mode == ContactEditMode.manualAddress
          ? manual
          : parsed[currency] != null
              ? parsed
              : manual;

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
    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> saveManualAddress() async {
    _ensureRecord();

    final map = manual.putIfAbsent(currency, () => {});
    final oldLabel = isAddressEdit ? _originalLabel : null;
    final newLabel = label.trim().isEmpty ? currency.title : label.trim();
    final newAddress = address.trim();

    if (oldLabel != null && oldLabel != newLabel) map.remove(oldLabel);
    map[newLabel] = newAddress;
    manual[currency] = Map.of(map);

    record!.setManualAddress(currency, newLabel, newAddress);
    _rememberOriginal();
    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> saveParsedAddress() async {
    _ensureRecord();

    final blockKey = handleKey.trim().isEmpty ? _defaultHandleKey() : handleKey.trim();
    final block = parsedBlocks.putIfAbsent(blockKey, () => {});
    final map = block.putIfAbsent(currency, () => {});

    final oldLabel = isAddressEdit ? _originalLabel : null;
    final newLabel = label.trim().isEmpty ? currency.title : label.trim();
    final newAddress = address.trim();

    if (oldLabel != null && oldLabel != newLabel) map.remove(oldLabel);
    map[newLabel] = newAddress;
    parsedBlocks[blockKey] = {for (final e in block.entries) e.key: Map.of(e.value)};

    record!.setParsedAddress(blockKey, currency, newLabel, newAddress);
    _rememberOriginal(blockKey: blockKey);
    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> deleteCurrentAddress() async {
    if (!isAddressEdit) return;
    _ensureRecord();

    if (mode == ContactEditMode.manualAddress) {
      final map = manual[_originalCur]!;
      map.remove(_originalLabel);
      if (map.isEmpty) manual.remove(_originalCur);
      manual[_originalCur!] = Map.of(map);

      record!.removeManualAddress(_originalCur!, _originalLabel!);
    } else {
      final block = parsedBlocks[_originalHandleKey]!;
      final curMap = block[_originalCur]!;
      curMap.remove(_originalLabel);
      if (curMap.isEmpty) block.remove(_originalCur);
      if (block.isEmpty)
        parsedBlocks.remove(_originalHandleKey);
      else
        parsedBlocks[_originalHandleKey!] = {for (final e in block.entries) e.key: Map.of(e.value)};

      record!.removeParsedAddress(_originalHandleKey!, _originalCur!, _originalLabel!);
    }

    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> deleteParsedBlock(String handleKey) async {
    if (!parsedBlocks.containsKey(handleKey)) return;

    parsedBlocks.remove(handleKey);
    record!.removeParsedAddress(handleKey, null, null);
    state = ExecutedSuccessfullyState();
  }

  @action
  Future<void> deleteContact() async {
    if (record == null) return;

    await record!.original.delete();
    record = null;
    reset();
    state = ExecutedSuccessfullyState();
  }

  @action
  void reset() {
    name = handle = profileName = description = imagePath = '';
    label = address = handleKey = '';
    currency = CryptoCurrency.xmr;
    manual.clear();
    parsed.clear();
    parsedBlocks.clear();
    _originalCur = null;
    _originalLabel = null;
    _originalAddress = null;
    _originalHandleKey = null;
    state = InitialExecutionState();
  }

  void _initMapsFromRecord() {
    if (record == null) return;

    manual = ObservableMap.of(record!.manual);
    parsed = ObservableMap.of(record!.parsedByCurrency);
    parsedBlocks = ObservableMap.of(record!.parsedBlocks);
  }

  void _ensureRecord() {
    if (record != null) return;
    final newContact = Contact(name: name.trim().isEmpty ? 'No name' : name, address: '');
    box.put(newContact.key, newContact);
    record = ContactRecord(box, newContact);
  }

  String _defaultHandleKey() => '${sourceType.label}-${handle}'.trim();

  void _rememberOriginal({String? blockKey}) {
    _originalCur = currency;
    _originalLabel = label.trim().isEmpty ? currency.title : label.trim();
    _originalAddress = address.trim();
    _originalHandleKey = blockKey ?? _defaultHandleKey();
  }

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
