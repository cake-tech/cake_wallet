import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_parser.dart";
import "package:cake_wallet/core/anypay/anypay_router.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const recipient = "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41";
  const usdtEthContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const btcAddress = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";
  const xmrAddress =
      "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A";
  const tronAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
  const solAddress = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";

  final usdt = Erc20Token(
    name: "Tether",
    symbol: "USDT",
    contractAddress: usdtEthContract,
    decimal: 6,
  );

  WalletInfo walletOf(WalletType type) => WalletInfo.external(
        id: "id-${type.name}",
        name: "wallet-${type.name}",
        type: type,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "",
      );

  WalletSnapshot snapshot({
    WalletType type = WalletType.ethereum,
    int? chainId,
    List<WalletInfo> wallets = const [],
    bool hasEvmProxy = true,
    bool hasSolanaProxy = true,
    bool hasTronProxy = true,
  }) =>
      WalletSnapshot(
        type: type,
        currentWalletIsEvm: isEVMCompatibleChain(type),
        currentChainId: chainId,
        wallets: wallets,
        supportedEvmChains: hasEvmProxy
            ? const {
                1: WalletType.ethereum,
                137: WalletType.polygon,
                8453: WalletType.base,
              }
            : const {},
        hasEvmProxy: hasEvmProxy,
        hasSolanaProxy: hasSolanaProxy,
        hasTronProxy: hasTronProxy,
      );

  AnyPayRequest parse(String input) => AnyPayParser.fromRaw(input);

  group("evm routing", () {
    test("explicit chain matching the current wallet applies directly", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient@1?value=1e18"),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });

    test("explicit chain differing from the current wallet goes cross chain", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient@8453?value=1e18"),
        snapshot(chainId: 1, wallets: [walletOf(WalletType.base)]),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayCrossChainPayment>());
      final crossChain = decision as AnyPayCrossChainPayment;
      expect(crossChain.targetChainId, 8453);
      expect(crossChain.targetWalletType, WalletType.base);
      expect(crossChain.hasCompatibleWallet, true);
    });

    test("cross chain with no wallet for the target offers no compatible wallet", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient@8453?value=1e18"),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayCrossChainPayment).hasCompatibleWallet, false);
    });

    test("unsupported explicit chain is rejected with its id", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient@10?value=1e18"),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayUnsupportedNetwork).chainId, 10);
    });

    test("chainless request binds to the current evm chain", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient?value=1e18"),
        snapshot(type: WalletType.base, chainId: 8453),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });

    test("chainless request at a non evm wallet targets mainnet cross chain", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient?value=1e18"),
        snapshot(type: WalletType.monero, wallets: [walletOf(WalletType.ethereum)]),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayCrossChainPayment).targetChainId, 1);
    });

    test("raw evm address at an evm wallet applies directly", () {
      final decision = AnyPayRouter.route(
        parse(recipient),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });

    test("raw evm address at a non evm wallet asks for a network choice", () {
      final decision = AnyPayRouter.route(
        parse(recipient),
        snapshot(type: WalletType.solana),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayEvmNetworkChoice>());
    });

    test("resolved token on the current chain applies with the token", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$usdtEthContract/transfer?address=$recipient&uint256=2000000"),
        snapshot(type: WalletType.base, chainId: 8453),
        TokenResolved(token: usdt, chainId: 8453, amountOverride: "2"),
      );

      final apply = decision as AnyPayApplyToCurrentWallet;
      expect(apply.token, usdt);
      expect(apply.amountOverride, "2");
    });

    test("chainless token resolved on another chain reroutes there", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$usdtEthContract/transfer?address=$recipient&uint256=2000000"),
        snapshot(type: WalletType.base, chainId: 8453, wallets: [walletOf(WalletType.ethereum)]),
        TokenResolved(token: usdt, chainId: 1, amountOverride: "2"),
      );

      final crossChain = decision as AnyPayCrossChainPayment;
      expect(crossChain.targetChainId, 1);
      expect(crossChain.token, usdt);
    });

    test("an unknown token never falls back to the native asset", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=2000000"),
        snapshot(chainId: 1),
        const TokenUnknown(usdtEthContract),
      );

      expect(decision, isA<AnyPayUnsupportedToken>());
      expect((decision as AnyPayUnsupportedToken).contract, usdtEthContract);
    });

    test("an unsupported network wins over an unknown token", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$usdtEthContract@10/transfer?address=$recipient&uint256=2000000"),
        snapshot(chainId: 1),
        const TokenUnknown(usdtEthContract),
      );

      expect((decision as AnyPayUnsupportedNetwork).chainId, 10);
    });

    test("evm address without the evm proxy applies as plain input", () {
      final decision = AnyPayRouter.route(
        parse(recipient),
        snapshot(type: WalletType.monero, hasEvmProxy: false),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
      expect((decision as AnyPayApplyToCurrentWallet).token, null);
    });
  });

  group("non evm routing", () {
    test("address matching the current wallet applies directly", () {
      final decision = AnyPayRouter.route(
        parse(xmrAddress),
        snapshot(type: WalletType.monero),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });

    test("btc address at another wallet goes cross chain with its wallets", () {
      final decision = AnyPayRouter.route(
        parse(btcAddress),
        snapshot(type: WalletType.monero, wallets: [walletOf(WalletType.bitcoin)]),
        const NoTokenRequested(),
      );

      final crossChain = decision as AnyPayCrossChainPayment;
      expect(crossChain.targetWalletType, WalletType.bitcoin);
      expect(crossChain.hasCompatibleWallet, true);
    });

    test("btc address with no bitcoin wallet leaves only the swap offer", () {
      final decision = AnyPayRouter.route(
        parse(btcAddress),
        snapshot(type: WalletType.monero),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayCrossChainPayment).hasCompatibleWallet, false);
    });

    test("tron address at another wallet goes cross chain to tron", () {
      final decision = AnyPayRouter.route(
        parse(tronAddress),
        snapshot(chainId: 1, wallets: [walletOf(WalletType.tron)]),
        const NoTokenRequested(),
      );

      final crossChain = decision as AnyPayCrossChainPayment;
      expect(crossChain.targetWalletType, WalletType.tron);
      expect(crossChain.targetChainId, null);
      expect(crossChain.wallets.length, 1);
    });

    test("solana address without the solana proxy applies as plain input", () {
      final decision = AnyPayRouter.route(
        parse(solAddress),
        snapshot(chainId: 1, hasSolanaProxy: false),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });

    test("an unknown non evm token never falls back to the native asset", () {
      final decision = AnyPayRouter.route(
        parse("solana:$solAddress?amount=3&spl-token=$solAddress"),
        snapshot(type: WalletType.solana),
        const TokenUnknown(solAddress),
      );

      expect(decision, isA<AnyPayUnsupportedToken>());
    });

    test("solana token resolved on the current wallet applies with the token", () {
      const splToken = CryptoCurrency.usdtSol;
      final decision = AnyPayRouter.route(
        parse("solana:$solAddress?amount=3&spl-token=$solAddress"),
        snapshot(type: WalletType.solana),
        const TokenResolved(token: splToken, amountOverride: "3"),
      );

      final apply = decision as AnyPayApplyToCurrentWallet;
      expect(apply.token, splToken);
      expect(apply.amountOverride, "3");
    });
  });

  group("native request currency", () {
    test("an explicit native request with an amount carries its currency", () {
      final decision = AnyPayRouter.route(
        parse("ethereum:$recipient@1?value=2e18"),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayApplyToCurrentWallet).fallbackCurrency, CryptoCurrency.eth);
    });

    test("a raw address carries no fallback currency", () {
      final decision = AnyPayRouter.route(
        parse(recipient),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect((decision as AnyPayApplyToCurrentWallet).fallbackCurrency, null);
    });
  });

  group("degenerate input", () {
    test("empty input is invalid", () {
      final decision = AnyPayRouter.route(
        parse(""),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayEmptyInput>());
    });

    test("undetectable text applies as plain input for the validator to reject", () {
      final decision = AnyPayRouter.route(
        parse("definitelynotanaddress"),
        snapshot(chainId: 1),
        const NoTokenRequested(),
      );

      expect(decision, isA<AnyPayApplyToCurrentWallet>());
    });
  });

  group("requested evm chain", () {
    test("explicit binding wins over the wallet chain", () {
      final request = parse("ethereum:$recipient@137?value=1e18");

      expect(AnyPayRouter.requestedEvmChainId(request, snapshot(chainId: 1)), 137);
    });

    test("chainless binding takes the wallet chain", () {
      final request = parse("ethereum:$recipient?value=1e18");

      expect(
        AnyPayRouter.requestedEvmChainId(
          request,
          snapshot(type: WalletType.base, chainId: 8453),
        ),
        8453,
      );
    });

    test("chainless binding defaults to mainnet without an evm wallet", () {
      final request = parse("ethereum:$recipient?value=1e18");

      expect(
        AnyPayRouter.requestedEvmChainId(request, snapshot(type: WalletType.monero)),
        1,
      );
    });

    test("raw addresses bind no target", () {
      expect(AnyPayRouter.requestedEvmChainId(parse(recipient), snapshot(chainId: 1)), null);
    });
  });
}
