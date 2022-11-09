import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/yat_record.dart';
import 'package:flutter/material.dart';

enum ParseFrom { unstoppableDomains, openAlias, yatRecord, fio, notParsed }

class ParsedAddress {
  ParsedAddress({
    required this.addresses,
    this.name = '',
    this.description = '',
    this.parseFrom = ParseFrom.notParsed,
  });
  
  factory ParsedAddress.fetchEmojiAddress({
    List<YatRecord>? addresses, 
    required String name,
    }){
      if (addresses?.isEmpty ?? true) {
        return ParsedAddress(
          addresses: [name], parseFrom: ParseFrom.yatRecord);
      }
      return ParsedAddress(
        addresses: addresses!.map((e) => e.address).toList(),
        name: name,
        parseFrom: ParseFrom.yatRecord,
      );
  }

  factory ParsedAddress.fetchUnstoppableDomainAddress({
    String? address, 
    required String name,
  }){
      if (address?.isEmpty ?? true) {
        return ParsedAddress(addresses: [name]);
      }
      return ParsedAddress(
        addresses: [address!],
        name: name,
        parseFrom: ParseFrom.unstoppableDomains,
      );
  }

  factory ParsedAddress.fetchOpenAliasAddress({OpenaliasRecord? record, required String name}){
    final formattedName = OpenaliasRecord.formatDomainName(name);
    if (record == null || record.address.contains(formattedName)) {
        return ParsedAddress(addresses: [name]);
      }
      return ParsedAddress(
        addresses: [record.address],
        name: record.name,
        description: record.description,
        parseFrom: ParseFrom.openAlias,
      );
  }

  factory ParsedAddress.fetchFioAddress({required String address, required String name}){
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: ParseFrom.fio,
    );
  }

  final List<String> addresses;
  final String name;
  final String description;
  final ParseFrom parseFrom;
}
