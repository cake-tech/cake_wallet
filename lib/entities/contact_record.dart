import 'dart:io';

import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/entities/record.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'contact_record.g.dart';

class ContactRecord = ContactRecordBase with _$ContactRecord;

abstract class ContactRecordBase extends Record<Contact> with Store implements ContactBase {
  ContactRecordBase(Box<Contact> box, Contact original)
      : name = original.name,
        handle = original.handle,
        profileName = original.profileName,
        description = original.description,
        imagePath = original.imagePath,
        sourceType = original.source,
        manual = ObservableMap.of(original.manualByCurrency),
        parsedBlocks = ObservableMap.of({
          for (final h in original.parsedByHandle.entries)
            h.key: {
              for (final cur in h.value.entries)
                CryptoCurrency.deserialize(raw: cur.key): Map<String, String>.of(cur.value)
            }
        }),
        super(box, original);

  @observable
  String name, handle, profileName, description, imagePath;
  @observable
  AddressSource sourceType;

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> manual;

  @observable
  ObservableMap<String, Map<CryptoCurrency, Map<String, String>>> parsedBlocks;

  @computed
  Map<CryptoCurrency, Map<String, String>> get parsedByCurrency {
    final out = <CryptoCurrency, Map<String, String>>{};
    parsedBlocks.forEach((_, byCur) {
      byCur.forEach((cur, lbl) => out.putIfAbsent(cur, () => {})..addAll(lbl));
    });
    return out;
  }

  @computed
  File? get avatarFile => imagePath.isEmpty ? null : File(imagePath);

  @computed
  ImageProvider get avatarProvider => (avatarFile?.existsSync() ?? false)
      ? FileImage(avatarFile!)
      : const AssetImage('assets/images/profile.png');

  @override
  void toBind(Contact c) {
    reaction((_) => name, (v) => c.name = v);
    reaction((_) => handle, (v) => c.handle = v);
    reaction((_) => profileName, (v) => c.profileName = v);
    reaction((_) => description, (v) => c.description = v);
    reaction((_) => imagePath, (v) => c.imagePath = v);
    reaction((_) => sourceType, (v) => c.source = v);
  }

  @override
  void fromBind(Contact c) {
    name = c.name;
    handle = c.handle;
    profileName = c.profileName;
    description = c.description;
    imagePath = c.imagePath;
    sourceType = c.source;
  }

  @action
  void setManualAddress(CryptoCurrency cur, String label, String addr) {
    manual.putIfAbsent(cur, () => {})[label] = addr;
    _flushManual();
  }

  @action
  void removeManualAddress(CryptoCurrency cur, String label) {
    final map = manual[cur];
    if (map == null) return;
    map.remove(label);
    if (map.isEmpty) manual.remove(cur);
    _flushManual();
  }

  @action
  void setParsedAddress(String blockKey, CryptoCurrency cur, String label, String addr) {
    final block = parsedBlocks.putIfAbsent(blockKey, () => {});
    block.putIfAbsent(cur, () => {})[label] = addr;
    parsedBlocks[blockKey] = {for (final e in block.entries) e.key: Map.of(e.value)};
    _flushParsed();
  }

  @action
  void removeParsedAddress(String blockKey, CryptoCurrency? cur, String? label) {
    final block = parsedBlocks[blockKey];
    if (block == null) return;

    if (cur == null) {
      parsedBlocks.remove(blockKey);
      _flushParsed();
      return;
    }

    final map = block[cur];
    if (map == null) return;

    if (label == null) {
      block.remove(cur);
    } else {
      map.remove(label);
      if (map.isEmpty) block.remove(cur);
    }

    if (block.isEmpty) {
      parsedBlocks.remove(blockKey);
    } else {
      parsedBlocks[blockKey] = {for (final e in block.entries) e.key: Map.of(e.value)};
    }

    _flushParsed();
  }

  void _flushManual() {
    original
      ..manualAddresses = {
        for (final e in manual.entries) e.key.raw: Map<String, String>.of(e.value)
      }
      ..lastChange = DateTime.now();
  }

  void _flushParsed() {
    original
      ..parsedByHandle = {
        for (final h in parsedBlocks.entries)
          h.key: {for (final cur in h.value.entries) cur.key.raw: Map<String, String>.of(cur.value)}
      }
      ..lastChange = DateTime.now();
  }

  @action
  void replaceParsedBlock(String handleKey, Map<CryptoCurrency, Map<String, String>> newBlock) {
    parsedBlocks[handleKey] = {
      for (final e in newBlock.entries) e.key: Map<String, String>.of(e.value)
    };

    original.parsedByHandle = {
      for (final h in parsedBlocks.entries)
        h.key: {for (final cur in h.value.entries) cur.key.raw: Map<String, String>.of(cur.value)}
    };
    original.lastChange = DateTime.now();
  }

  @override
  String address = '';
  @override
  CryptoCurrency type = CryptoCurrency.btc;
}
