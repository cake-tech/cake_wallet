import "package:cake_wallet/core/universal_address_detector.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const recipient = "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41";
  const usdtEthContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const daiEthContract = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const usdtBaseContract = "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2";

  final usdt = Erc20Token(
    name: "Tether",
    symbol: "USDT",
    contractAddress: usdtEthContract,
    decimal: 6,
  );
  final dai = Erc20Token(
    name: "Dai",
    symbol: "DAI",
    contractAddress: daiEthContract,
    decimal: 18,
  );

  group("cross generation QR matrix", () {
    test("new app mainnet USDT QR parses with explicit chain and amount", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "200.172148",
        contractAddress: usdtEthContract,
        tokenDecimals: 6,
      ).toString();

      final request = PaymentRequest.fromUri(Uri.parse(uri));
      expect(request.chainId, 1);
      expect(request.contractAddress, usdtEthContract);
      expect(request.resolveTokenAmount(usdt), "200.172148");
    });

    test("new app mainnet DAI QR emits both params and the amount wins", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "1.5",
        contractAddress: daiEthContract,
      ).toString();

      expect(uri.contains("uint256=1500000000000000000"), true);
      expect(uri.contains("amount=1.5"), true);

      final request = PaymentRequest.fromUri(Uri.parse(uri));
      expect(request.chainId, 1);
      expect(request.resolveTokenAmount(dai), "1.5");
    });

    test("old app chainless USDT QR resolves through the legacy fallback", () {
      final request = PaymentRequest.fromUri(
        Uri.parse(
          "ethereum:$usdtEthContract/transfer?address=$recipient&uint256=2000000000000000000",
        ),
      );

      expect(request.chainId, null);
      expect(request.resolveTokenAmount(usdt), "2");
    });

    test("team lead legacy URI resolves to the intended two USDT", () {
      final request = PaymentRequest.fromUri(
        Uri.parse(
          "ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=2013999999999999744",
        ),
      );

      expect(request.chainId, 1);
      expect(request.resolveTokenAmount(usdt), "2.013999999999999744");
    });

    test("external QR with a true six decimal uint256 resolves directly", () {
      final request = PaymentRequest.fromUri(
        Uri.parse("ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=1000000"),
      );

      expect(request.resolveTokenAmount(usdt), "1");
    });

    test("old app native scientific value parses without a chain", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:$recipient?value=2.014e18"));

      expect(request.chainId, null);
      expect(request.amount, "2.014");
    });

    test("new app native QR round trips with the explicit chain", () {
      final uri = ERC681URI(chainId: 1, address: recipient, amount: "2.5", contractAddress: null)
          .toString();
      expect(uri, "ethereum:$recipient@1?value=2.5e18");

      final request = PaymentRequest.fromUri(Uri.parse(uri));
      expect(request.chainId, 1);
      expect(request.amount, "2.5");
    });

    test("new app base token QR carries the base chain", () {
      final uri = ERC681URI(
        chainId: 8453,
        address: recipient,
        amount: "3",
        contractAddress: usdtBaseContract,
        tokenDecimals: 6,
      ).toString();

      final request = PaymentRequest.fromUri(Uri.parse(uri));
      expect(request.chainId, 8453);
      expect(request.contractAddress, usdtBaseContract);
      expect(request.amount, "3");
    });
  });

  group("emitter invariants", () {
    test("every emitted ethereum URI names its chain", () {
      final uris = [
        ERC681URI(chainId: 1, address: recipient, amount: "", contractAddress: null),
        ERC681URI(chainId: 1, address: recipient, amount: "1", contractAddress: null),
        ERC681URI(
          chainId: 1,
          address: recipient,
          amount: "1",
          contractAddress: usdtEthContract,
          tokenDecimals: 6,
        ),
        ERC681URI(chainId: 8453, address: recipient, amount: "", contractAddress: usdtBaseContract),
      ];

      for (final uri in uris) {
        expect(uri.toString().contains("@"), true, reason: uri.toString());
      }
    });

    test("six decimal tokens emit no uint256", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "1.5",
        contractAddress: usdtEthContract,
        tokenDecimals: 6,
      ).toString();

      expect(uri.contains("uint256"), false);
      expect(uri.contains("amount=1.5"), true);
    });

    test("a stored raw amount is passed through verbatim", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "",
        contractAddress: usdtEthContract,
        tokenDecimals: 6,
        rawTokenAmount: "1000000",
      ).toString();

      expect(uri, "ethereum:$usdtEthContract@1/transfer?address=$recipient&uint256=1000000");
    });

    test("comma decimal separators are normalized", () {
      final uri = ERC681URI(
        chainId: 1,
        address: recipient,
        amount: "2,5",
        contractAddress: usdtEthContract,
        tokenDecimals: 6,
      ).toString();

      expect(uri.contains("amount=2.5"), true);
    });
  });

  group("hostile and external input", () {
    test("EIP681 pay- prefix parses for native transfers", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:pay-$recipient@1?value=1e18"));

      expect(request.address, recipient);
      expect(request.chainId, 1);
      expect(request.amount, "1");
    });

    test("EIP681 pay- prefix parses for token transfers", () {
      final request = PaymentRequest.fromUri(
        Uri.parse("ethereum:pay-$usdtEthContract@1/transfer?address=$recipient&uint256=1000000"),
      );

      expect(request.contractAddress, usdtEthContract);
      expect(request.address, recipient);
      expect(request.resolveTokenAmount(usdt), "1");
    });

    test("a trailing chain separator defaults to mainnet", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:$recipient@?value=1e18"));

      expect(request.address, recipient);
      expect(request.chainId, 1);
    });

    test("a non numeric chain id defaults to mainnet", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:$recipient@abc"));

      expect(request.address, recipient);
      expect(request.chainId, 1);
    });

    test("an ENS style target degrades to the raw name without throwing", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:vitalik.eth?amount=1"));

      expect(request.address, "vitalik.eth");
      expect(request.amount, "1");
    });

    test("junk after the scheme does not throw", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:junk"));

      expect(request.address, "junk");
    });

    test("an empty ethereum URI does not throw", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:"));

      expect(request.address, "");
    });

    test("a non numeric native value yields no amount", () {
      final request = PaymentRequest.fromUri(Uri.parse("ethereum:$recipient?value=abc"));

      expect(request.address, recipient);
      expect(request.amount, "");
    });

    test("an unknown contract function still extracts the contract", () {
      final request = PaymentRequest.fromUri(
        Uri.parse("ethereum:$usdtEthContract@1/approve?address=$recipient"),
      );

      expect(request.contractAddress, usdtEthContract);
      expect(request.address, recipient);
    });

    test("plain text input falls back to an address passthrough", () {
      final request = PaymentRequest.fromString("definitelynotauri");

      expect(request.address, "definitelynotauri");
      expect(request.scheme, "");
    });
  });

  group("resolveTokenAmount boundaries", () {
    test("one billion whole tokens is still read with the token decimals", () {
      final request =
          PaymentRequest("addr", "", "", "ethereum", null, rawTokenAmount: "1000000000000000");

      expect(request.resolveTokenAmount(usdt), "1000000000");
    });

    test("just past the plausibility bound flips to the legacy reading", () {
      final request =
          PaymentRequest("addr", "", "", "ethereum", null, rawTokenAmount: "1000000000000001");

      expect(request.resolveTokenAmount(usdt), "0.001000000000000001");
    });

    test("eighteen decimal tokens never take the legacy branch", () {
      final request =
          PaymentRequest("addr", "", "", "ethereum", null, rawTokenAmount: "50000000000000000000");

      expect(request.resolveTokenAmount(dai), "50");
    });

    test("garbage raw amounts resolve to null", () {
      final request =
          PaymentRequest("addr", "", "", "ethereum", null, rawTokenAmount: "not a number");

      expect(request.resolveTokenAmount(usdt), null);
    });
  });

  group("send page reconstruction round trip", () {
    test("an explicit chain request rebuilds into the same payment", () {
      final original = PaymentRequest.fromUri(
        Uri.parse("ethereum:$usdtBaseContract@8453/transfer?address=$recipient&uint256=3000000"),
      );

      final rebuilt = ERC681URI(
        address: original.address,
        amount: original.amount,
        contractAddress: original.contractAddress,
        chainId: original.chainId ?? 1,
        rawTokenAmount: original.rawTokenAmount,
      ).toString();

      final reparsed = PaymentRequest.fromUri(Uri.parse(rebuilt));
      expect(reparsed.chainId, 8453);
      expect(reparsed.contractAddress, usdtBaseContract);
      expect(reparsed.rawTokenAmount, "3000000");
      expect(reparsed.address, recipient);
    });

    test("a dual param request survives reconstruction with the raw intact", () {
      final original = PaymentRequest.fromUri(
        Uri.parse(
          "ethereum:$daiEthContract@1/transfer?address=$recipient&uint256=1500000000000000000&amount=1.5",
        ),
      );

      final rebuilt = ERC681URI(
        address: original.address,
        amount: original.amount,
        contractAddress: original.contractAddress,
        chainId: original.chainId ?? 1,
        rawTokenAmount: original.rawTokenAmount,
      ).toString();

      final reparsed = PaymentRequest.fromUri(Uri.parse(rebuilt));
      expect(reparsed.amount, "1.5");
      expect(reparsed.rawTokenAmount, "1500000000000000000");
    });
  });

  group("detector supplements", () {
    test("pay- prefixed URIs are detected as EVM payments", () {
      final result = UniversalAddressDetector.detectAddress("ethereum:pay-$recipient@1?value=1e18");

      expect(result.isValid, true);
      expect(result.detectedWalletType, WalletType.ethereum);
    });

    test("an unsupported chain id is still surfaced for routing", () {
      final result = UniversalAddressDetector.detectAddress("ethereum:$recipient@10?value=1e18");

      expect(result.isValid, true);
      expect(result.chainId, 10);
    });
  });
}
