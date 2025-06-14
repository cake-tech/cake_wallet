import 'dart:io';

import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/record.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'contact_record.g.dart';

class ContactRecord = ContactRecordBase with _$ContactRecord;

abstract class ContactRecordBase extends Record<Contact> with Store implements ContactBase {
  ContactRecordBase(Box<Contact> source, Contact original)
      : name = original.name,
        handle = original.handle,
        profileName = original.profileName,
        description = original.description,
        imagePath = original.imagePath,
        sourceType = original.source,
        parsedAddresses = ObservableMap.of(original.parsedByCurrency),
        manualAddresses = ObservableMap.of(original.manualByCurrency),
        super(source, original);

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

  String address = '';

  CryptoCurrency type = CryptoCurrency.btc;

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> parsedAddresses;

  @observable
  ObservableMap<CryptoCurrency, Map<String, String>> manualAddresses;

  @override
  void toBind(Contact original) {
    reaction((_) => name, (v) => original.name = v);
    reaction((_) => handle, (v) => original.handle = v);
    reaction((_) => profileName, (v) => original.profileName = v);
    reaction((_) => description, (v) => original.description = v);
    reaction((_) => imagePath, (v) => original.imagePath = v);
    reaction((_) => sourceType, (v) => original.source = v);

    bool _different(Map<String, String>? inner, String lbl, String addr) =>
        inner == null || inner[lbl] != addr;

    reaction((_) => Map.of(parsedAddresses), (_) {
      parsedAddresses.forEach((cur, byLabel) {
        byLabel.forEach((lbl, addr) {
          final inner = original.parsedAddresses[cur.raw];
          if (_different(inner, lbl, addr)) {
            original.setAddress(
              currency: cur,
              label: lbl,
              address: addr,
              isManual: false,
            );
          }
        });
      });
    });

    reaction((_) => Map.of(manualAddresses), (_) {
      manualAddresses.forEach((cur, byLabel) {
        byLabel.forEach((lbl, addr) {
          final inner = original.manualAddresses[cur.raw];
          if (_different(inner, lbl, addr)) {
            original.setAddress(
              currency: cur,
              label: lbl,
              address: addr,
              isManual: true,
            );
          }
        });
      });
    });
  }

  @override
  void fromBind(Contact original) {
    name = original.name;
    handle = original.handle;
    profileName = original.profileName;
    description = original.description;
    imagePath = original.imagePath;
    sourceType = original.source;

    parsedAddresses = ObservableMap.of({
      for (final e in original.parsedByCurrency.entries) e.key: Map<String, String>.of(e.value)
    });

    manualAddresses = ObservableMap.of({
      for (final e in original.manualByCurrency.entries) e.key: Map<String, String>.of(e.value)
    });
  }

  @computed
  File? get avatarFile => imagePath.isEmpty ? null : File(imagePath);

  @computed
  ImageProvider get avatarProvider {
    final f = avatarFile;
    return (f != null && f.existsSync())
        ? FileImage(f)
        : const AssetImage('assets/images/profile.png');
  }

  @action
  void setParsedAddress(CryptoCurrency cur, String label, String addr) {
    final oldInner = parsedAddresses[cur] ?? {};
    parsedAddresses[cur] = {...oldInner, label: addr};
  }
}
