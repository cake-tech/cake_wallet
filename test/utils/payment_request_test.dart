import "package:cake_wallet/utils/payment_request.dart";
import "package:cw_core/erc20_token.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("PaymentRequest", () {
    group("Ethereum URIs", () {
      test("extract address and raw token amount from EIP681 Uri with contract", () {
        final uri = Uri.parse(
          "ethereum:0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174@1/transfer?address=0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41&uint256=2000000000000000000",
        );
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "");
        expect(paymentRequest.rawTokenAmount, "2000000000000000000");
      });

      test("extract address and amount from EIP681 Uri", () {
        final uri = Uri.parse(
          "ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41@1?value=2000000000000000000",
        );
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "2");
      });

      test("extract address and amount from Cake Style Uri", () {
        final uri = Uri.parse("ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41@1?amount=2.00");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "2.00");
      });

      test("extract address from EIP681 Uri with contract", () {
        final uri = Uri.parse(
          "ethereum:0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174@1/transfer?address=0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41",
        );
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "");
      });

      test("extract address and raw token amount from EIP681 Uri with contract and no chainId", () {
        final uri = Uri.parse(
          "ethereum:0x1234567890abcdef1234567890abcdef12345678/transfer?address=0xabcdef1234567890abcdef1234567890abcdef12&uint256=1000000000000000000",
        );
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xabcdef1234567890abcdef1234567890abcdef12");
        expect(paymentRequest.amount, "");
        expect(paymentRequest.rawTokenAmount, "1000000000000000000");
      });

      test("extract address from minimal EIP681 Uri", () {
        final uri = Uri.parse("ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "");
      });
    });

    group("resolveTokenAmount", () {
      final usdt = Erc20Token(
        name: "Tether",
        symbol: "USDT",
        contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        decimal: 6,
      );
      final dai = Erc20Token(
        name: "Dai",
        symbol: "DAI",
        contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
        decimal: 18,
      );

      test("converts the raw uint256 using the token decimals", () {
        final uri = Uri.parse(
          "ethereum:0xdAC17F958D2ee523a2206206994597C13D831ec7@1/transfer?address=0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41&uint256=1000000",
        );
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.resolveTokenAmount(usdt), "1");
      });

      test("converts an 18 decimal raw amount unchanged", () {
        final paymentRequest =
            PaymentRequest("addr", "", "", "ethereum", null, rawTokenAmount: "1500000000000000000");

        expect(paymentRequest.resolveTokenAmount(dai), "1.5");
      });

      test("falls back to the legacy 18 decimal reading for implausibly large amounts", () {
        final paymentRequest = PaymentRequest(
          "addr",
          "",
          "",
          "ethereum",
          null,
          rawTokenAmount: "50000000000000000000",
        );

        expect(paymentRequest.resolveTokenAmount(usdt), "50");
      });

      test("prefers the decimal amount over the raw token amount", () {
        final paymentRequest =
            PaymentRequest("addr", "2.5", "", "ethereum", null, rawTokenAmount: "1000000");

        expect(paymentRequest.resolveTokenAmount(usdt), "2.5");
      });

      test("returns null when there is no amount at all", () {
        final paymentRequest = PaymentRequest("addr", "", "", "ethereum", null);

        expect(paymentRequest.resolveTokenAmount(usdt), null);
      });
    });
  });
}
