import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/yat_record.dart';
import 'package:cw_core/crypto_currency.dart';

const supportedSources = [
  AddressSource.twitter,
  AddressSource.unstoppableDomains,
  AddressSource.mastodon,
  AddressSource.bip353,
  AddressSource.fio,
  AddressSource.zanoAlias,
  AddressSource.thorChain,
  AddressSource.ens,
  AddressSource.yatRecord,
  AddressSource.openAlias,
  AddressSource.wellKnown,
  AddressSource.nostr,
];

///Do not use '-' in the label, it is used to separate the label from the alias.
enum AddressSource {
  twitter(
      label: 'X',
      iconPath: 'assets/images/x_social.png',
      alias: '@username',
      supportedCurrencies: [
        CryptoCurrency.xmr,
        CryptoCurrency.btc,
        CryptoCurrency.ltc,
        CryptoCurrency.eth,
        CryptoCurrency.bnb,
        CryptoCurrency.sol,
        CryptoCurrency.maticpoly
      ]),
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
      supportedCurrencies: [
        CryptoCurrency.xmr,
        CryptoCurrency.btc,
        CryptoCurrency.eth,
        CryptoCurrency.ltc
      ]),
  fio(label: 'FIO', iconPath: 'assets/images/fio.png', alias: 'user@domain', supportedCurrencies: [
    CryptoCurrency.xmr,
    CryptoCurrency.btc,
    CryptoCurrency.ltc,
    CryptoCurrency.eth,
    CryptoCurrency.bnb,
    CryptoCurrency.sol,
    CryptoCurrency.maticpoly,
  ]),
  ens(
      label: 'Ethereum Name Service',
      iconPath: 'assets/images/ens_icon.png',
      alias: 'domain.eth',
      supportedCurrencies: [CryptoCurrency.xmr, CryptoCurrency.btc, CryptoCurrency.eth]),
  mastodon(
      label: 'Mastodon',
      iconPath: 'assets/images/mastodon.svg',
      alias: 'user@domain.tld',
      supportedCurrencies: [
        CryptoCurrency.xmr,
        CryptoCurrency.btc,
        CryptoCurrency.ltc,
        CryptoCurrency.eth,
        CryptoCurrency.bnb,
        CryptoCurrency.sol,
        CryptoCurrency.maticpoly
      ]),
  nostr(
      label: 'Nostr',
      iconPath: 'assets/images/nostr.png',
      supportedCurrencies: [
        CryptoCurrency.xmr,
        CryptoCurrency.btc,
        CryptoCurrency.ltc,
        CryptoCurrency.eth,
        CryptoCurrency.bnb,
        CryptoCurrency.sol,
        CryptoCurrency.maticpoly
      ]),
  thorChain(
      label: 'ThorChain',
      iconPath: 'assets/images/thorchain.png',
      supportedCurrencies: CryptoCurrency.all),
  wellKnown(
      label: '.wellknown',
      iconPath: '', // TODO provide an icon
      supportedCurrencies: [CryptoCurrency.nano]),
  zanoAlias(
      label: 'Zano Alias',
      iconPath: 'assets/images/zano_icon.png',
      supportedCurrencies: [CryptoCurrency.zano]),
  bip353(
      label: 'BIP353',
      iconPath: 'assets/images/btc.png',
      alias: 'user@domain.com',
      supportedCurrencies: [CryptoCurrency.btc]),
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

class ParsedAddress {
  const ParsedAddress({
    required this.parsedAddressByCurrencyMap,
    this.manualAddressByCurrencyMap,
    this.addressSource = AddressSource.notParsed,
    this.handle = '',
    this.profileImageUrl = '',
    this.profileName = '',
    this.description = '',
    this.bip353DnsProof,
  });

  final Map<CryptoCurrency, String> parsedAddressByCurrencyMap;
  final Map<CryptoCurrency, String>? manualAddressByCurrencyMap;
  final AddressSource addressSource;
  final String handle;
  final String profileImageUrl;
  final String profileName;
  final String description;
  final String? bip353DnsProof;

  ParsedAddress copyWith({
    Map<CryptoCurrency, String>? parsedAddressByCurrencyMap,
    Map<CryptoCurrency, String>? manualAddressByCurrencyMap,
    AddressSource? addressSource,
    String? handle,
    String? profileImageUrl,
    String? profileName,
    String? description,
    String? bip353DnsProof,
  }) {
    return ParsedAddress(
      parsedAddressByCurrencyMap: parsedAddressByCurrencyMap ?? this.parsedAddressByCurrencyMap,
      manualAddressByCurrencyMap: manualAddressByCurrencyMap ?? this.manualAddressByCurrencyMap,
      addressSource: addressSource ?? this.addressSource,
      handle: handle ?? this.handle,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileName: profileName ?? this.profileName,
      description: description ?? this.description,
      bip353DnsProof: bip353DnsProof ?? this.bip353DnsProof,
    );
  }
}
