import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/anypay/anypay_parser.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const recipient = "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41";
  const usdtEthContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

  group("chain binding", () {
    test("explicit ethereum chain binds explicitly", () {
      final request = AnyPayParser.fromRaw(
        "ethereum:$recipient@8453?value=1e18",
      );

      expect(request.chainBinding, isA<ExplicitEvmChain>());
      expect((request.chainBinding as ExplicitEvmChain).chainId, 8453);
    });

    test("ethereum without a chain id stays chainless", () {
      final request = AnyPayParser.fromRaw(
        "ethereum:$usdtEthContract/transfer?address=$recipient&uint256=1000000",
      );

      expect(request.chainBinding, isA<ChainlessEvm>());
      expect(request.hasContract, true);
    });

    test("non evm schemes bind no evm chain", () {
      final request = AnyPayParser.fromRaw(
        "bitcoin:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
      );

      expect(request.chainBinding, isA<NoEvmBinding>());
    });

    test("raw evm addresses bind no evm chain", () {
      final request = AnyPayParser.fromRaw(recipient);

      expect(request.chainBinding, isA<NoEvmBinding>());
      expect(request.detection.isValid, true);
    });

    test("an evm chain scheme binds its chain explicitly", () {
      final request = AnyPayParser.fromRaw("polygon:$recipient");

      expect((request.chainBinding as ExplicitEvmChain).chainId, 137);
    });
  });

  group("payment request reconstruction", () {
    test("an explicit chain request keeps its chain and raw amount", () {
      final original = PaymentRequest.fromUri(
        Uri.parse("ethereum:$usdtEthContract@8453/transfer?address=$recipient&uint256=3000000"),
      );

      final request = AnyPayParser.fromPaymentRequest(original);

      expect(request.rawInput.contains("@8453"), true);
      expect(request.paymentRequest.rawTokenAmount, "3000000");
      expect((request.chainBinding as ExplicitEvmChain).chainId, 8453);
    });

    test("a chainless request rebuilds with a placeholder but keeps the chainless binding", () {
      final original = PaymentRequest.fromUri(
        Uri.parse("ethereum:$usdtEthContract/transfer?address=$recipient&uint256=1000000"),
      );

      final request = AnyPayParser.fromPaymentRequest(original);

      expect(request.rawInput.contains("@1/"), true);
      expect(request.chainBinding, isA<ChainlessEvm>());
      expect(request.detection.isValid, true);
    });

    test("a tron token request keeps its contract on the payment request", () {
      final original = PaymentRequest.fromUri(
        Uri.parse("tron:TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t?token=TTokenContract111111111111111111"),
      );

      final request = AnyPayParser.fromPaymentRequest(original);

      expect(request.contractAddress, "TTokenContract111111111111111111");
      expect(request.chainBinding, isA<NoEvmBinding>());
    });

    test("a non evm request rebuilds scheme address and amount", () {
      final original = PaymentRequest("someaddress", "1.25", "", "monero", null);

      final request = AnyPayParser.fromPaymentRequest(original);

      expect(request.rawInput, "monero:someaddress?amount=1.25");
    });

    test("a lightning request passes the invoice through untouched", () {
      final original = PaymentRequest("lnbc1invoice", "", "", "lightning", null);

      final request = AnyPayParser.fromPaymentRequest(original);

      expect(request.rawInput, "lnbc1invoice");
    });
  });
}
