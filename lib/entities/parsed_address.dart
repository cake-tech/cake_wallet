import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/yat_record.dart';

enum AddressSource {
  twitter(
    label: 'X',
    iconPath: 'assets/images/x_social.png',
    alias: '@username'
  ),
  unstoppableDomains(
    label: 'Unstoppable Domains',
    iconPath: 'assets/images/ud.png',
    alias: 'domain.tld',
  ),
  openAlias(
    label: 'OpenAlias',
    iconPath: 'assets/images/open_alias.png',
    alias: 'oa',
  ),
  yatRecord(
    label: 'Yat',
    iconPath: 'assets/images/yat_mini_logo.png',
  ),
  fio(
    label: 'FIO',
    iconPath: 'assets/images/fio.png',
  ),
  ens(
    label: 'Ethereum Name Service',
    iconPath: 'assets/images/ens_icon.png',
  ),
  mastodon(
    label: 'Mastodon',
    iconPath: 'assets/images/mastodon.svg',
    alias: 'user@domain.tld'
  ),
  nostr(
    label: 'Nostr',
    iconPath: 'assets/images/nostr.png',
  ),
  thorChain(
    label: 'ThorChain',
    iconPath: 'assets/images/thorchain.png',
  ),
  wellKnown(
    label: '.well-known',
    iconPath: 'assets/icons/wk.svg',
  ),
  zanoAlias(
    label: 'Zano Alias',
    iconPath: 'assets/images/zano_icon.png',
  ),
  bip353(
    label: 'BIP-353',
    iconPath: 'assets/images/bip353.svg',
  ),
  contact(
    label: 'Contact',
    iconPath: '',
  ),
  notParsed(
    label: 'Unknown',
    iconPath: '',
  );

  const AddressSource({
    required this.label,
    required this.iconPath,
    this.alias = '',
  });

  final String label;
  final String iconPath;
  final String alias;

  static List<AddressSource> supported({
    Set<AddressSource> exclude = const {AddressSource.notParsed, AddressSource.contact},
  }) =>
      values.where((src) => !exclude.contains(src)).toList();
}

class ParsedAddress {
  ParsedAddress({
    required this.addresses,
    this.name = '',
    this.description = '',
    this.profileImageUrl = '',
    this.profileName = '',
    this.parseFrom = AddressSource.notParsed,
  });

  factory ParsedAddress.fetchEmojiAddress({
    List<YatRecord>? addresses,
    required String name,
  }) {
    if (addresses?.isEmpty ?? true) {
      return ParsedAddress(addresses: [name], parseFrom: AddressSource.yatRecord);
    }
    return ParsedAddress(
      addresses: addresses!.map((e) => e.address).toList(),
      name: name,
      parseFrom: AddressSource.yatRecord,
    );
  }

  factory ParsedAddress.fetchUnstoppableDomainAddress({
    String? address,
    required String name,
  }) {
    if (address?.isEmpty ?? true) {
      return ParsedAddress(addresses: [name]);
    }
    return ParsedAddress(
      addresses: [address!],
      name: name,
      parseFrom: AddressSource.unstoppableDomains,
    );
  }

  factory ParsedAddress.fetchBip353AddressAddress({
    required String address,
    required String name,
  }) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.bip353,
    );
  }

  factory ParsedAddress.fetchOpenAliasAddress(
      {required OpenaliasRecord record, required String name}) {
    if (record.address.isEmpty) {
      return ParsedAddress(addresses: [name]);
    }
    return ParsedAddress(
      addresses: [record.address],
      name: record.name,
      description: record.description,
      parseFrom: AddressSource.openAlias,
    );
  }

  factory ParsedAddress.fetchFioAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.fio,
    );
  }

  factory ParsedAddress.fetchTwitterAddress(
      {required String address,
      required String name,
      required String profileImageUrl,
      required String profileName,
      String? description}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      description: description ?? '',
      profileImageUrl: profileImageUrl,
      profileName: profileName,
      parseFrom: AddressSource.twitter,
    );
  }

  factory ParsedAddress.fetchMastodonAddress(
      {required String address,
      required String name,
      required String profileImageUrl,
      required String profileName}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.mastodon,
      profileImageUrl: profileImageUrl,
      profileName: profileName,
    );
  }

  factory ParsedAddress.fetchContactAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.contact,
    );
  }

  factory ParsedAddress.fetchEnsAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.ens,
    );
  }

  factory ParsedAddress.nostrAddress(
      {required String address,
      required String name,
      required String profileImageUrl,
      required String profileName}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.nostr,
      profileImageUrl: profileImageUrl,
      profileName: profileName,
    );
  }

  factory ParsedAddress.thorChainAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.thorChain,
    );
  }

  factory ParsedAddress.zanoAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.zanoAlias,
    );
  }

  factory ParsedAddress.fetchWellKnownAddress({required String address, required String name}) {
    return ParsedAddress(
      addresses: [address],
      name: name,
      parseFrom: AddressSource.wellKnown,
    );
  }

  final List<String> addresses;
  final String name;
  final String description;
  final String profileImageUrl;
  final String profileName;
  final AddressSource parseFrom;
}
