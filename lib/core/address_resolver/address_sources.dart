import 'package:cake_wallet/core/address_validator.dart';
import 'package:cw_core/crypto_currency.dart';

enum AddressSource {
  twitter(label: 'X', iconPath: 'assets/new-ui/address_sources/x.svg', alias: '@username'),
  unstoppableDomains(
      label: 'Unstoppable Domains',
      iconPath: 'assets/new-ui/address_sources/unstoppable.svg',
      alias: 'domain.tld'),
  openAlias(
      label: 'OpenAlias',
      iconPath: 'assets/new-ui/address_sources/openalias.svg',
      alias: 'name.domain.tld'),
  yatRecord(label: 'Yat', iconPath: 'assets/new-ui/address_sources/yat.svg', alias: '🎂🎂🎂'),
  fio(label: 'FIO', iconPath: 'assets/new-ui/address_sources/fio.svg', alias: 'user@domain'),
  ens(
      label: 'Ethereum Name Service',
      iconPath: 'assets/new-ui/address_sources/ens.svg',
      alias: 'domain.eth'),
  mastodon(
      label: 'Mastodon',
      iconPath: 'assets/new-ui/address_sources/mastodon.svg',
      alias: '@username@domain.tld'),
  nostr(
      label: 'Nostr',
      iconPath: 'assets/new-ui/address_sources/nostr.svg',
      alias: 'user@domain.tld'),
  thorChain(
      label: 'ThorChain',
      iconPath: 'assets/new-ui/address_sources/icon-thorchain.svg',
      alias: 'name'),
  wellKnown(
      label: '.wellknown',
      iconPath: 'assets/new-ui/address_sources/wellknown.svg',
      alias: 'domain.tld'),
  zanoAlias(
      label: 'Zano Alias', iconPath: 'assets/new-ui/address_sources/zano.svg', alias: '@alias'),
  bip353(
      label: 'BIP353',
      iconPath: 'assets/new-ui/address_sources/bip353.svg',
      alias: 'user@domain.com'),
  zcashAddress(
      label: 'Zcash.me',
      iconPath: 'assets/new-ui/address_sources/icon-zcash-me.svg',
      alias: 'zcash.me/username'),
  zcashName(
      label: 'Zcash Names',
      iconPath: 'assets/new-ui/address_sources/icon-zcashnames.svg',
      alias: 'name.zec'),
  lnurlPay(
      label: 'LNURL Pay',
      iconPath: 'assets/new-ui/address_sources/icon-lnurl-pay.svg',
      alias: 'user@domain.com'),
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
