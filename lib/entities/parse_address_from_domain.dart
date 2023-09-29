import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/yat_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/ens_record.dart';
import 'package:cake_wallet/entities/openalias_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/entities/unstoppable_domain_address.dart';
import 'package:cake_wallet/entities/emoji_string_extension.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/twitter/twitter_api.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/entities/fio_address_provider.dart';

class AddressResolver {
  AddressResolver({required this.yatService, required this.walletType});

  final YatService yatService;
  final WalletType walletType;

  static const unstoppableDomains = [
    'crypto',
    'zil',
    'x',
    'wallet',
    'bitcoin',
    '888',
    'nft',
    'dao',
    'blockchain',
    'polygon',
    'klever',
    'hi',
    'kresus',
    'anime',
    'manga',
    'binanceus'
  ];

  static String? extractAddressByType({required String raw, required CryptoCurrency type}) {
    final addressPattern = AddressValidator.getAddressFromStringPattern(type);

    if (addressPattern == null) {
      throw Exception('Unexpected token: $type for getAddressFromStringPattern');
    }

    final match = RegExp(addressPattern).firstMatch(raw);
    return match?.group(0)?.replaceAll(RegExp('[^0-9a-zA-Z]'), '');
  }

  Future<ParsedAddress> resolve(String text, String ticker) async {
    try {
      if (text.startsWith('@') && !text.substring(1).contains('@')) {
        final formattedName = text.substring(1);
        final twitterUser = await TwitterApi.lookupUserByName(userName: formattedName);
        final addressFromBio = extractAddressByType(
            raw: twitterUser.description, type: CryptoCurrency.fromString(ticker));
        if (addressFromBio != null) {
          return ParsedAddress.fetchTwitterAddress(address: addressFromBio, name: text);
        }
        final tweets = twitterUser.tweets;
        if (tweets != null) {
          var subString = StringBuffer();
          tweets.forEach((item) {
            subString.writeln(item.text);
          });
          final userTweetsText = subString.toString();
          final addressFromPinnedTweet =
              extractAddressByType(raw: userTweetsText, type: CryptoCurrency.fromString(ticker));

          if (addressFromPinnedTweet != null) {
            return ParsedAddress.fetchTwitterAddress(address: addressFromPinnedTweet, name: text);
          }
        }
      }
      if (!text.startsWith('@') && text.contains('@') && !text.contains('.')) {
        final bool isFioRegistered = await FioAddressProvider.checkAvail(text);
        if (isFioRegistered) {
          final address = await FioAddressProvider.getPubAddress(text, ticker);
          return ParsedAddress.fetchFioAddress(address: address, name: text);
        }
      }
      if (text.hasOnlyEmojis) {
        if (walletType != WalletType.haven) {
          final addresses = await yatService.fetchYatAddress(text, ticker);
          return ParsedAddress.fetchEmojiAddress(addresses: addresses, name: text);
        }
      }
      final formattedName = OpenaliasRecord.formatDomainName(text);
      final domainParts = formattedName.split('.');
      final name = domainParts.last;

      if (domainParts.length <= 1 || domainParts.first.isEmpty || name.isEmpty) {
        return ParsedAddress(addresses: [text]);
      }

      if (unstoppableDomains.any((domain) => name.trim() == domain)) {
        final address = await fetchUnstoppableDomainAddress(text, ticker);
        return ParsedAddress.fetchUnstoppableDomainAddress(address: address, name: text);
      }

      if (text.endsWith(".eth")) {
        var wallet = getIt.get<AppStore>().wallet!;
        final address = await EnsRecord.fetchEnsAddress(text, wallet: wallet);
        if (address.isNotEmpty && address != "0x0000000000000000000000000000000000000000") {
          return ParsedAddress.fetchEnsAddress(name: text, address: address);
        }
      }

      if (formattedName.contains(".")) {
        final txtRecord = await OpenaliasRecord.lookupOpenAliasRecord(formattedName);
        if (txtRecord != null) {
          final record = await OpenaliasRecord.fetchAddressAndName(
              formattedName: formattedName, ticker: ticker, txtRecord: txtRecord);
          return ParsedAddress.fetchOpenAliasAddress(record: record, name: text);
        }
      }
    } catch (e) {
      print(e.toString());
    }

    return ParsedAddress(addresses: [text]);
  }
}
