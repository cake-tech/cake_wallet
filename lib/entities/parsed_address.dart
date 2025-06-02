import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/yat_record.dart';
import 'package:cw_core/crypto_currency.dart';

enum AddressSource {
  twitter(label: 'X', iconPath: 'assets/images/x_social.png', alias: '@username'),
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
  mastodon(label: 'Mastodon', iconPath: 'assets/images/mastodon.svg', alias: 'user@domain.tld'),
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
  ParsedAddress(
      {required this.addressByCurrencyMap,
      this.addressSource = AddressSource.notParsed,
      this.handle = '',
      this.profileImageUrl = '',
      this.profileName = '',
      this.description = ''});

  final Map<CryptoCurrency, String> addressByCurrencyMap;
  final AddressSource addressSource;
  final String handle;
  final String profileImageUrl;
  final String profileName;
  final String description;
}
