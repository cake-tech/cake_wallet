import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_parser.dart";
import "package:cake_wallet/core/anypay/anypay_resolver.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeTokenLookup implements AnyPayTokenLookup {
  _FakeTokenLookup({this.onFindToken, this.onFindChainId});

  final Future<CryptoCurrency?> Function({required WalletType walletType, required String address})?
      onFindToken;
  final Future<int?> Function(String contractAddress, {int? excludingChainId})? onFindChainId;

  @override
  Future<CryptoCurrency?> findTokenByAddress({
    required WalletType walletType,
    required String address,
  }) {
    if (onFindToken == null) {
      fail("no token lookup expected");
    }
    return onFindToken!(walletType: walletType, address: address);
  }

  @override
  Future<int?> findEvmChainIdForContract(String contractAddress, {int? excludingChainId}) {
    if (onFindChainId == null) {
      fail("no chain sweep expected");
    }
    return onFindChainId!(contractAddress, excludingChainId: excludingChainId);
  }
}

void main() {
  const recipient = "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41";
  const usdtEthContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const solAddress = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
  const usdcSolMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";

  final usdt = Erc20Token(
    name: "Tether",
    symbol: "USDT",
    contractAddress: usdtEthContract,
    decimal: 6,
  );

  WalletSnapshot snapshot({
    WalletType type = WalletType.ethereum,
    int? chainId,
    bool hasEvmProxy = true,
  }) =>
      WalletSnapshot(
        type: type,
        currentWalletIsEvm:
            type == WalletType.ethereum || type == WalletType.polygon || type == WalletType.base,
        currentChainId: chainId,
        wallets: const [],
        // The service builds an empty chain map when the evm proxy is absent.
        supportedEvmChains: hasEvmProxy
            ? const {
                1: WalletType.ethereum,
                137: WalletType.polygon,
                8453: WalletType.base,
              }
            : const {},
        hasEvmProxy: hasEvmProxy,
        hasSolanaProxy: true,
        hasTronProxy: true,
      );

  AnyPayRequest parse(String input) => AnyPayParser.fromRaw(input);

  test("a request without a contract needs no resolution", () async {
    final resolver = AnyPayResolver(tokenLookup: _FakeTokenLookup());

    final resolution = await resolver.resolve(
      parse("ethereum:$recipient@1?value=1e18"),
      snapshot(chainId: 1),
    );

    expect(resolution, isA<NoTokenRequested>());
  });

  test("a token on the explicit target chain resolves with its amount", () async {
    final lookedUp = <WalletType>[];
    final resolver = AnyPayResolver(
      tokenLookup: _FakeTokenLookup(
        onFindToken: ({required walletType, required address}) async {
          lookedUp.add(walletType);
          return walletType == WalletType.ethereum ? usdt : null;
        },
      ),
    );

    final resolution = await resolver.resolve(
      parse("ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=1000000"),
      snapshot(type: WalletType.base, chainId: 8453),
    );

    final resolved = resolution as TokenResolved;
    expect(lookedUp, [WalletType.ethereum]);
    expect(resolved.chainId, 1);
    expect(resolved.token, usdt);
    expect(resolved.amountOverride, "1");
  });

  test("an unknown token on an explicit chain is not swept to other chains", () async {
    bool sweepCalled = false;
    final resolver = AnyPayResolver(
      tokenLookup: _FakeTokenLookup(
        onFindToken: ({required walletType, required address}) async => null,
        onFindChainId: (contract, {excludingChainId}) async {
          sweepCalled = true;
          return 137;
        },
      ),
    );

    final resolution = await resolver.resolve(
      parse("ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=1000000"),
      snapshot(chainId: 1),
    );

    expect(resolution, isA<TokenUnknown>());
    expect(sweepCalled, false);
  });

  test("a chainless token unknown on the current chain reroutes through the sweep", () async {
    final resolver = AnyPayResolver(
      tokenLookup: _FakeTokenLookup(
        onFindToken: ({required walletType, required address}) async =>
            walletType == WalletType.ethereum ? usdt : null,
        onFindChainId: (contract, {excludingChainId}) async {
          expect(excludingChainId, 8453);
          return 1;
        },
      ),
    );

    final resolution = await resolver.resolve(
      parse("ethereum:$usdtEthContract/transfer?address=$recipient&uint256=2000000"),
      snapshot(type: WalletType.base, chainId: 8453),
    );

    final resolved = resolution as TokenResolved;
    expect(resolved.chainId, 1);
    expect(resolved.amountOverride, "2");
  });

  test("a chainless token unknown everywhere stays unknown", () async {
    final resolver = AnyPayResolver(
      tokenLookup: _FakeTokenLookup(
        onFindToken: ({required walletType, required address}) async => null,
        onFindChainId: (contract, {excludingChainId}) async => null,
      ),
    );

    final resolution = await resolver.resolve(
      parse("ethereum:$usdtEthContract/transfer?address=$recipient&uint256=2000000"),
      snapshot(chainId: 1),
    );

    expect((resolution as TokenUnknown).contract, usdtEthContract);
  });

  test("a solana token resolves against the detected wallet type", () async {
    const usdcSol = CryptoCurrency.usdtSol;
    final resolver = AnyPayResolver(
      tokenLookup: _FakeTokenLookup(
        onFindToken: ({required walletType, required address}) async {
          expect(walletType, WalletType.solana);
          expect(address, usdcSolMint);
          return usdcSol;
        },
      ),
    );

    final resolution = await resolver.resolve(
      parse("solana:$solAddress?amount=3&spl-token=$usdcSolMint"),
      snapshot(type: WalletType.monero),
    );

    final resolved = resolution as TokenResolved;
    expect(resolved.chainId, null);
    expect(resolved.token, usdcSol);
    expect(resolved.amountOverride, "3");
  });

  test("an evm contract without the evm proxy stays unknown without any lookups", () async {
    final resolver = AnyPayResolver(tokenLookup: _FakeTokenLookup());

    final resolution = await resolver.resolve(
      parse("ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=1000000"),
      snapshot(hasEvmProxy: false),
    );

    expect(resolution, isA<TokenUnknown>());
  });
}
