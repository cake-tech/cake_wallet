import 'package:cake_wallet/entities/parse_address_from_domain.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressResolver', () {
    // late MockYatService mockYatService;
    // late MockWalletBase mockWallet;
    // late MockSettingsStore mockSettingsStore;
    // late MockBuildContext mockContext;
    // late AddressResolver addressResolver;
    //
    // setUp(() {
    //   mockYatService = MockYatService();
    //   mockWallet = MockWalletBase();
    //   mockSettingsStore = MockSettingsStore();
    //   mockContext = MockBuildContext();
    //
    //   when(mockWallet.type).thenReturn(WalletType.bitcoin);
    //   when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
    //
    //   addressResolver = AddressResolver(
    //     yatService: mockYatService,
    //     wallet: mockWallet,
    //     settingsStore: mockSettingsStore,
    //   );
    // });

    group('extractAddressByType', () {
      test('extracts Bitcoin address correctly', () {
        final raw =
            'My Bitcoin address is bc1qhg4l43pmq5v5atmtlr7gnwyuxs043cvrut5hkq please use it';
        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.btc,
        );
        expect(result, 'bc1qhg4l43pmq5v5atmtlr7gnwyuxs043cvrut5hkq');
      });

      test('extracts Ethereum address correctly', () {
        final raw =
            'Send ETH to 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 thanks';
        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.eth,
        );
        expect(result, '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2');
      });

      test('extracts Monero address correctly', () {
        final raw =
            'XMR: 85s6zfxGAkdCN21h566R8EFDSfThxCrFiEkhw3JEtaXN2DDfahABLXTjRj385Ro7om5saGWJG7iuE6EyW5MYcoz93DLvNqh';
        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.xmr,
        );
        expect(result,
            '85s6zfxGAkdCN21h566R8EFDSfThxCrFiEkhw3JEtaXN2DDfahABLXTjRj385Ro7om5saGWJG7iuE6EyW5MYcoz93DLvNqh');
      });

      test('extracts Bitcoin Cash address correctly', () {
        final raw =
            'BCH: bitcoincash:qr2z7dusk64qnq97azhg0u0hlf7qgwwfzyj92jgmqj';
        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.bch,
        );
        expect(
            result, 'bitcoincash:qr2z7dusk64qnq97azhg0u0hlf7qgwwfzyj92jgmqj');
      });

      test('extracts Nano address correctly', () {
        final raw =
            'NANO: nano_1natrium1o3z5519ifou7xii8crpxpk8y65qmkih8e8bpsjri651oza8imdd';
        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.nano,
        );
        expect(result,
            'nano_1natrium1o3z5519ifou7xii8crpxpk8y65qmkih8e8bpsjri651oza8imdd');
      });

      test('returns null for unsupported currency', () {
        final raw = 'Some text without an address';
        expect(
            () => AddressResolver.extractAddressByType(
                  raw: raw,
                  type: CryptoCurrency.btc,
                ),
            returnsNormally);

        final result = AddressResolver.extractAddressByType(
          raw: raw,
          type: CryptoCurrency.btc,
        );
        expect(result, isNull);
      });

      test('extracts monero address from URI', () {
        final raw =
            'monero_wallet:467iotZU5tvG26k2xdZWkJ7gwATFVhfbuV3yDoWx5jHoPwxEi4f5BuJQwkP6GpCb1sZvUVB7nbSkgEuW8NKrh9KKRRga5qz?spend_key=029c559cd7669f14e91fd835144916009f8697ab5ac5c7f7c06e1ff869c17b0b&view_key=afaf646edbff3d3bcee8efd3383ffe5d20c947040f74e1110b70ca0fbb0ef90d';
        final result = AddressResolver.extractAddressByType(
            raw: raw,
            type: CryptoCurrency.xmr,
            requireSurroundingWhitespaces: false);
        expect(result,
            '467iotZU5tvG26k2xdZWkJ7gwATFVhfbuV3yDoWx5jHoPwxEi4f5BuJQwkP6GpCb1sZvUVB7nbSkgEuW8NKrh9KKRRga5qz');
      });

      test('extracts monero address from Tweet', () {
        final raw = '''
#XMR
89bH6i3ftaWSWuPJJYSQuuApWJ8xzinCEbbnAXN1Z3mGGUuAFdpBUg82R9MvJDSheJ6kW2dyMQEFUGM4tsZqRb2Q75UXqvc

#BTC Silent Payments 
sp1qq0avpawwjg4l66p6lqafj0vlvm6rlhdc6qt0r6dfual835vhs3gvkq63pechaqezvn7j7uj2jucwj5k7nenpw2r86wf42xv6wqdvxuk5rggrul45

#LTC MWEB
ltcmweb1qq0at62jjucmawxp78qutn0cqwkwahcfx7fxls0r2ma5llg5w6wyy2qe20gxa3rku2658j88zg9d2j4ttpw35k0a5nrg93h5nq3wyvkcgwc3q4dgc
        ''';
        final resultXmr = AddressResolver.extractAddressByType(
            raw: raw, type: CryptoCurrency.xmr);
        expect(resultXmr,
            '89bH6i3ftaWSWuPJJYSQuuApWJ8xzinCEbbnAXN1Z3mGGUuAFdpBUg82R9MvJDSheJ6kW2dyMQEFUGM4tsZqRb2Q75UXqvc');
        final resultBtc = AddressResolver.extractAddressByType(
            raw: raw, type: CryptoCurrency.btc);
        expect(resultBtc,
            'sp1qq0avpawwjg4l66p6lqafj0vlvm6rlhdc6qt0r6dfual835vhs3gvkq63pechaqezvn7j7uj2jucwj5k7nenpw2r86wf42xv6wqdvxuk5rggrul45');
        final resultLtc = AddressResolver.extractAddressByType(
            raw: raw, type: CryptoCurrency.ltc);
        expect(resultLtc,
            'ltcmweb1qq0at62jjucmawxp78qutn0cqwkwahcfx7fxls0r2ma5llg5w6wyy2qe20gxa3rku2658j88zg9d2j4ttpw35k0a5nrg93h5nq3wyvkcgwc3q4dgc');
      });

      // test('throws exception for unexpected token', () {
      //   // Create a custom crypto currency that won't have a pattern
      //   final customCurrency = CryptoCurrency('CUSTOM', 'Custom');
      //   expect(() => AddressResolver.extractAddressByType(
      //     raw: 'Some text',
      //     type: customCurrency,
      //   ), throwsException);
      // });
    });
    //
    // group('isEmailFormat', () {
    //   test('returns true for valid email format', () {
    //     expect(addressResolver.isEmailFormat('user@example.com'), isTrue);
    //     expect(addressResolver.isEmailFormat('name.surname@domain.co.uk'), isTrue);
    //     expect(addressResolver.isEmailFormat('user123@subdomain.example.org'), isTrue);
    //   });
    //
    //   test('returns false for invalid email format', () {
    //     expect(addressResolver.isEmailFormat('user@'), isFalse);
    //     expect(addressResolver.isEmailFormat('@domain.com'), isFalse);
    //     expect(addressResolver.isEmailFormat('user@domain'), isFalse);
    //     expect(addressResolver.isEmailFormat('user.domain.com'), isFalse);
    //     expect(addressResolver.isEmailFormat('user@domain@com'), isFalse);
    //     expect(addressResolver.isEmailFormat('bc1qhg4l43pmq5v5atmtlr7gnwyuxs043cvrut5hkq'), isFalse);
    //   });
    // });
    //
    // group('resolve', () {
    //   test('returns ParsedAddress with original text when no resolution is possible', () async {
    //     final text = 'bc1qhg4l43pmq5v5atmtlr7gnwyuxs043cvrut5hkq';
    //     final result = await addressResolver.resolve(mockContext, text, CryptoCurrency.btc);
    //
    //     expect(result, isA<ParsedAddress>());
    //     expect(result.addresses, [text]);
    //   });
    //
    //   // Note: More comprehensive tests for the resolve method would require
    //   // mocking all the external services and APIs that the method calls.
    //   // This would be quite extensive and would require setting up mock
    //   // responses for each type of address resolution.
    // });

    group('unstoppableDomains', () {
      test('contains expected TLDs', () {
        expect(AddressResolver.unstoppableDomains, contains('crypto'));
        expect(AddressResolver.unstoppableDomains, contains('eth'));
        expect(AddressResolver.unstoppableDomains, contains('bitcoin'));
        expect(AddressResolver.unstoppableDomains, contains('x'));
        expect(AddressResolver.unstoppableDomains, contains('wallet'));
      });
    });
  });
}
