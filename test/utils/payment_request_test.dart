import 'package:cake_wallet/utils/payment_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentRequest', () {
    group('Ethereum URIs', () {
      test("extract address and amount from EIP681 Uri with contract", () {
        final uri = Uri.parse(
            "ethereum:0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174@1/transfer?address=0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41&uint256=2000000000000000000");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "2");
      });

      test("extract address and amount from EIP681 Uri", () {
        final uri = Uri.parse(
            "ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41@1?value=2000000000000000000");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "2");
      });

      test("extract address and amount from Cake Style Uri", () {
        final uri =
            Uri.parse("ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41@1?amount=2.00");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "2.00");
      });

      test("extract address from EIP681 Uri with contract", () {
        final uri = Uri.parse(
            "ethereum:0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174@1/transfer?address=0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "");
      });

      test("extract address and amount from EIP681 Uri with contract and no chainId", () {
        final uri = Uri.parse(
            "ethereum:0x1234567890abcdef1234567890abcdef12345678/transfer?address=0xabcdef1234567890abcdef1234567890abcdef12&uint256=1000000000000000000");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xabcdef1234567890abcdef1234567890abcdef12");
        expect(paymentRequest.amount, "1");
      });

      test("extract address from minimal EIP681 Uri", () {
        final uri = Uri.parse("ethereum:0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.address, "0xCfc1650da7C961FD82998e7e30ca5f699D0aBf41");
        expect(paymentRequest.amount, "");
      });
    });
  });
}
