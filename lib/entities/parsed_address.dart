import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/yat_record.dart';
import 'package:cw_core/crypto_currency.dart';

const supportedSources = [
  AddressSource.twitter,
  AddressSource.unstoppableDomains,
  AddressSource.ens,
  AddressSource.mastodon,
];

enum AddressSource {
  twitter(
      label: 'X',
      iconPath: 'assets/images/x_social.png',
      alias: '@username',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  unstoppableDomains(
      label: 'Unstoppable Domains',
      iconPath: 'assets/images/ud.png',
      alias: 'domain.tld',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  openAlias(
      label: 'OpenAlias',
      iconPath: 'assets/images/open_alias.png',
      alias: 'oa',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  yatRecord(
      label: 'Yat',
      iconPath: 'assets/images/yat_mini_logo.png',
      alias: '🎂🎂🎂',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  fio(
      label: 'FIO',
      iconPath: 'assets/images/fio.png',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  ens(
      label: 'Ethereum Name Service',
      iconPath: 'assets/images/ens_icon.png',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc, CryptoCurrency.eth]),
  mastodon(
      label: 'Mastodon',
      iconPath: 'assets/images/mastodon.svg',
      alias: 'user@domain.tld',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  nostr(
      label: 'Nostr',
      iconPath: 'assets/images/nostr.png',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  thorChain(
      label: 'ThorChain',
      iconPath: 'assets/images/thorchain.png',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  wellKnown(
      label: '.well-known',
      iconPath: 'assets/icons/wk.svg',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  zanoAlias(
      label: 'Zano Alias',
      iconPath: 'assets/images/zano_icon.png',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  bip353(
      label: 'BIP-353',
      iconPath: '',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc]),
  contact(label: 'Contact', iconPath: '', supportedCurrencies: []),
  notParsed(label: 'Unknown', iconPath: '', supportedCurrencies: []);

  const AddressSource({
    required this.label,
    required this.iconPath,
    this.alias = '',
    this.supportedCurrencies = const <CryptoCurrency>[],
  });

  final String label;
  final String iconPath;
  final String alias;
  final List<CryptoCurrency> supportedCurrencies;
}

extension AddressSourceIndex on AddressSource {
  int get raw => index;

  static AddressSource fromRaw(int raw) =>
      AddressSource.values[raw.clamp(0, AddressSource.values.length - 1)];
}

class ParsedAddress {
  const ParsedAddress({
    required this.parsedAddressByCurrencyMap,
    this.manualAddressByCurrencyMap,
    this.addressSource = AddressSource.notParsed,
    this.handle = '',
    this.profileImageUrl = '',
    this.profileName = '',
    this.description = '',
  });

  final Map<CryptoCurrency, String> parsedAddressByCurrencyMap;
  final Map<CryptoCurrency, String>? manualAddressByCurrencyMap;
  final AddressSource addressSource;
  final String handle;
  final String profileImageUrl;
  final String profileName;
  final String description;

  ParsedAddress copyWith({
    Map<CryptoCurrency, String>? parsedAddressByCurrencyMap,
    Map<CryptoCurrency, String>? manualAddressByCurrencyMap,
    AddressSource? addressSource,
    String? handle,
    String? profileImageUrl,
    String? profileName,
    String? description,
  }) {
    return ParsedAddress(
      parsedAddressByCurrencyMap: parsedAddressByCurrencyMap ?? this.parsedAddressByCurrencyMap,
      manualAddressByCurrencyMap: manualAddressByCurrencyMap ?? this.manualAddressByCurrencyMap,
      addressSource: addressSource ?? this.addressSource,
      handle: handle ?? this.handle,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileName: profileName ?? this.profileName,
      description: description ?? this.description,
    );
  }
}
