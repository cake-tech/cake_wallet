import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_electrumx_client.dart';
import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_models.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements NamecoinElectrumXClient {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockWallet extends Mock implements WalletBase {}

void main() {
  late _MockClient client;
  late NamecoinAddressProvider provider;
  late _MockWallet wallet;

  setUp(() {
    client = _MockClient();
    provider = NamecoinAddressProvider(client: client);
    wallet = _MockWallet();
  });

  test('handles only normalized Namecoin identifiers', () {
    expect(provider.canHandle('name.bit'), isTrue);
    expect(provider.canHandle('D/name'), isTrue);
    expect(provider.canHandle('id/name'), isTrue);
    expect(provider.canHandle('name.eth'), isFalse);
    expect(provider.canHandle('example.com'), isFalse);
    expect(provider.supportedCurrencies, CryptoCurrency.all);
  });

  test('appends Namecoin without changing legacy source indices', () {
    expect(AddressSourceIndex.fromRaw(AddressSource.openAlias.raw), AddressSource.openAlias);
    expect(AddressSourceIndex.fromRaw(AddressSource.notParsed.raw), AddressSource.notParsed);
    expect(AddressSourceIndex.fromRaw(AddressSource.namecoin.raw), AddressSource.namecoin);
    expect(AddressSourceIndex.fromRaw(9999), AddressSource.notParsed);
  });

  test('uses the persisted Namecoin lookup setting', () {
    final settings = _MockSettingsStore();
    when(() => settings.lookupsNamecoin).thenReturn(false);
    expect(provider.isEnabled(settings), isFalse);
    when(() => settings.lookupsNamecoin).thenReturn(true);
    expect(provider.isEnabled(settings), isTrue);
  });

  test('returns all currencies when contact creation has no upfront selection', () async {
    when(() => client.resolve('d/testls')).thenAnswer(
      (_) async => const NamecoinLookup(
        name: 'd/testls',
        value: '{"btc":"bc1-main","xmr":"4abc","usdterc20":"0x1234"}',
        txid: 'txid',
        height: 100,
        expiresIn: 35000,
      ),
    );

    final results = await provider.resolve(
      query: 'TestLS.bit',
      currencies: CryptoCurrency.all,
      wallet: wallet,
    );

    expect(results.single.parsedAddressByCurrencyMap, {
      CryptoCurrency.btc: 'bc1-main',
      CryptoCurrency.xmr: '4abc',
      CryptoCurrency.usdterc20: '0x1234',
    });
  });

  test('fails closed when the active currency is absent', () async {
    when(() => client.resolve('d/testls')).thenAnswer(
      (_) async => const NamecoinLookup(
        name: 'd/testls',
        value: '{"btc":"bc1-main"}',
        txid: 'txid',
        height: 100,
        expiresIn: 35000,
      ),
    );

    final results = await provider.resolve(
      query: 'd/testls',
      currencies: const [CryptoCurrency.xmr],
      wallet: wallet,
    );

    expect(results, isEmpty);
  });
}
