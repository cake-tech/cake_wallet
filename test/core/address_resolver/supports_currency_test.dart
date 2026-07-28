import 'package:cake_wallet/core/address_resolver/ens/ens_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/ens/ens_record.dart';
import 'package:cake_wallet/core/address_resolver/lnurl_pay/lnurl_pay_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/unstoppable/unstoppable_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zano/zano_alias_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_address_provider.dart';
import 'package:cake_wallet/core/address_resolver/zcash/zcash_me_address_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:ens_dart/ens_dart.dart' show CoinType;
import 'package:flutter_test/flutter_test.dart';

Erc20Token _token({required String symbol, required String contractAddress, String? tag}) =>
    Erc20Token(
      name: symbol,
      symbol: symbol,
      contractAddress: contractAddress,
      decimal: 6,
      tag: tag,
    );

void main() {
  // Ethereum mainnet USDT.
  final usdtEth =
      _token(symbol: 'USDT', contractAddress: '0xdac17f958d2ee523a2206206994597c13d831ec7', tag: 'ETH');
  // Polygon USDT - same ticker, different chain.
  final usdtPolygon =
      _token(symbol: 'USDT', contractAddress: '0xc2132d05d31c914a87c6611c10748aeb04b58e8f', tag: 'POL');

  group('AddressLookupProvider.supportsCurrency', () {
    group('ENS', () {
      final provider = EnsAddressProvider();

      test('supports native ETH', () {
        expect(provider.supportsCurrency(CryptoCurrency.eth), isTrue);
      });

      test('no longer claims BTC or XMR, whose only path is bare-hex', () {
        // fetchEnsAddress would route these to getCoinAddress(), which returns
        // hex.encode(bytes) - not a base58/bech32 address. Unstoppable Domains
        // serves .eth for these wallets instead.
        expect(provider.supportsCurrency(CryptoCurrency.btc), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.xmr), isFalse);
      });

      test('accepts runtime ERC-20 tokens on Ethereum mainnet', () {
        expect(provider.supportsCurrency(usdtEth), isTrue);
      });

      test('accepts const Ethereum mainnet ERC-20 currencies', () {
        // The exchange, contact and buy/sell screens pass these const entries
        // rather than runtime Erc20Token instances.
        for (final currency in const [
          CryptoCurrency.dai,
          CryptoCurrency.usdterc20,
          CryptoCurrency.usdc,
          CryptoCurrency.wbtc,
          CryptoCurrency.weth,
          CryptoCurrency.shib,
          CryptoCurrency.uni,
          CryptoCurrency.aave,
          CryptoCurrency.pepe,
          CryptoCurrency.steth,
        ]) {
          expect(provider.supportsCurrency(currency), isTrue,
              reason: '${currency.title} is an Ethereum mainnet ERC-20');
        }
      });

      test('rejects tokens on other EVM chains', () {
        expect(provider.supportsCurrency(usdtPolygon), isFalse);
        expect(
          provider.supportsCurrency(
            _token(
              symbol: 'USDC',
              contractAddress: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
              tag: 'BASE',
            ),
          ),
          isFalse,
        );
        expect(provider.supportsCurrency(CryptoCurrency.usdcpoly), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.usdtbsc), isFalse);
      });

      test('does not newly enable non-EVM or non-Ethereum EVM native coins', () {
        // getCoinAddress() returns bare hex, so LTC would be malformed.
        expect(provider.supportsCurrency(CryptoCurrency.ltc), isFalse);
        // addr(60) is the ETH record, not the chain's own record.
        expect(provider.supportsCurrency(CryptoCurrency.maticpoly), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.baseEth), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.arbEth), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.bnb), isFalse);
        expect(provider.supportsCurrency(CryptoCurrency.btcln), isFalse);
      });

      test('accepts MATIC, which is the Ethereum mainnet ERC-20, not Polygon', () {
        // CryptoCurrency.matic is tagged 'ETH'; CryptoCurrency.maticpoly is the
        // Polygon native coin and is tagged 'POL'.
        expect(provider.supportsCurrency(CryptoCurrency.matic), isTrue);
        expect(EnsRecord.getEnsCoinType(CryptoCurrency.matic), CoinType.ETH);
      });
    });

    group('Unstoppable Domains', () {
      final provider = UnstoppableAddressProvider();

      test('accepts any currency whose ticker can name a UD record', () {
        expect(provider.supportsCurrency(CryptoCurrency.xmr), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.btc), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.eth), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.ltc), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.sol), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.trx), isTrue);
      });

      test('accepts ERC-20 tokens', () {
        expect(provider.supportsCurrency(usdtEth), isTrue);
        expect(provider.supportsCurrency(usdtPolygon), isTrue);
      });

      test('rejects tickers that cannot form a record key', () {
        // 'USDC.E' would produce the malformed key `crypto.USDC.E.address`.
        expect(provider.supportsCurrency(CryptoCurrency.usdcEPoly), isFalse);
      });

      test('rejects Lightning, whose ticker is BTC', () {
        expect(provider.supportsCurrency(CryptoCurrency.btcln), isFalse);
      });

      test('still claims the .eth TLD, as the fallback behind ENS', () {
        expect(provider.canHandle('hiraya.eth'), isTrue);
        expect(provider.canHandle('wrenox.crypto'), isTrue);
      });
    });

    // AddressResolverService lists ENS before Unstoppable Domains, and runs
    // providers in order with first-non-empty-wins. That ordering cannot be
    // asserted here without a SettingsStore, but its blast radius can be: the
    // two providers overlap on exactly one TLD.
    group('ENS / Unstoppable Domains overlap', () {
      test('only .eth is claimed by both, so the reorder affects nothing else', () {
        final ens = EnsAddressProvider();

        for (final tld in UnstoppableAddressProvider.unstoppableDomains) {
          final query = 'somebody.$tld';
          if (ens.canHandle(query)) {
            expect(tld, 'eth', reason: '$query is claimed by ENS as well as UD');
          }
        }

        expect(ens.canHandle('hiraya.eth'), isTrue);
        expect(ens.canHandle('wrenox.crypto'), isFalse);
      });
    });

    group('currency-scoped providers are unchanged', () {
      test('LNURL-pay only supports Lightning', () {
        final provider = LNUrlPayAddressProvider();
        expect(provider.supportsCurrency(CryptoCurrency.btcln), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.btc), isFalse);
        expect(provider.supportsCurrency(usdtEth), isFalse);
      });

      test('Zano alias only supports Zano', () {
        final provider = ZanoAliasAddressProvider();
        expect(provider.supportsCurrency(CryptoCurrency.zano), isTrue);
        expect(provider.supportsCurrency(CryptoCurrency.btc), isFalse);
        expect(provider.supportsCurrency(usdtEth), isFalse);
      });

      test('Zcash providers only support ZEC', () {
        final nameProvider = ZcashNameAddressProvider();
        final meProvider = ZcashMeAddressProvider();

        for (final provider in [nameProvider, meProvider]) {
          expect(provider.supportsCurrency(CryptoCurrency.zec), isTrue);
          expect(provider.supportsCurrency(CryptoCurrency.btc), isFalse);
          expect(provider.supportsCurrency(usdtEth), isFalse);
        }
      });
    });
  });
}
