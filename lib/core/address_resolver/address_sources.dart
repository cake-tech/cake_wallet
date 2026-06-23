import 'package:cake_wallet/core/address_validator.dart';
import 'package:cw_core/crypto_currency.dart';

enum AddressSource {
  twitter(label: 'X', iconPath: 'assets/images/address_providers/x.svg', alias: '@username'),
  unstoppableDomains(
      label: 'Unstoppable Domains',
      iconPath: 'assets/images/address_providers/unstoppable.svg',
      alias: 'domain.tld'),
  openAlias(
      label: 'OpenAlias',
      iconPath: 'assets/images/address_providers/openalias.svg',
      alias: 'name.domain.tld'),
  yatRecord(label: 'Yat', iconPath: 'assets/images/address_providers/yat.svg', alias: '🎂🎂🎂'),
  fio(label: 'FIO', iconPath: 'assets/images/address_providers/fio.svg', alias: 'user@domain'),
  ens(
      label: 'Ethereum Name Service',
      iconPath: 'assets/images/address_providers/ens.svg',
      alias: 'domain.eth'),
  mastodon(
      label: 'Mastodon',
      iconPath: 'assets/images/address_providers/mastodon.svg',
      alias: '@username@domain.tld'),
  nostr(
      label: 'Nostr',
      iconPath: 'assets/images/address_providers/nostr.svg',
      alias: 'user@domain.tld'),
  thorChain(
      label: 'ThorChain', iconPath: 'assets/images/address_providers/thorchain.svg', alias: 'name'),
  wellKnown(
      label: '.wellknown',
      iconPath: 'assets/images/address_providers/wellknown.svg',
      alias: 'domain.tld'),
  zanoAlias(
      label: 'Zano Alias', iconPath: 'assets/images/address_providers/zano.svg', alias: '@alias'),
  bip353(
      label: 'BIP353',
      iconPath: 'assets/images/address_providers/bip353.svg',
      alias: 'user@domain.com'),
  zcashAddress(label: 'Zcash.me', iconPath: '', alias: 'zcash.me/username'),
  zcashName(label: 'Zcash Names', iconPath: '', alias: 'name.zec'),
  lnurlPay(label: 'LNURL Pay', iconPath: '', alias: 'user@domain.com'),
  contact(label: 'Contact', iconPath: ''),
  notParsed(label: 'Unknown', iconPath: ''),
  ;

  const AddressSource({
    required this.label,
    required this.iconPath,
    this.alias = '',
  });

  final String label;
  final String iconPath;
  final String alias;
}

extension AddressSourceIndex on AddressSource {
  int get raw => index;

  static AddressSource fromRaw(int raw) =>
      AddressSource.values[raw.clamp(0, AddressSource.values.length - 1)];
}

extension AddressSourceNameParser on AddressSource {
  static AddressSource fromLabel(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AddressSource.notParsed;
    }
    final needle = text.trim().toLowerCase();
    return AddressSource.values.firstWhere(
      (src) => src.label.toLowerCase() == needle,
      orElse: () => AddressSource.notParsed,
    );
  }
}
