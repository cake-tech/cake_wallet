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

    group('Zcash ZIP-321 URIs', () {
      test('extract address and amount from basic zcash URI', () {
        final uri = Uri.parse('zcash:u1abc123?amount=1.5');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.scheme, 'zcash');
        expect(paymentRequest.address, 'u1abc123');
        expect(paymentRequest.amount, '1.5');
        expect(paymentRequest.memo, isNull);
      });

      test('decode base64url memo from zcash URI', () {
        // "Hello World" in base64url = SGVsbG8gV29ybGQ=
        final uri = Uri.parse('zcash:u1addr?amount=0.001&memo=SGVsbG8gV29ybGQ=');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.scheme, 'zcash');
        expect(paymentRequest.address, 'u1addr');
        expect(paymentRequest.amount, '0.001');
        expect(paymentRequest.memo, 'Hello World');
      });

      test('decode base64url memo without padding', () {
        // "Hello" in base64url = SGVsbG8 (no padding)
        final uri = Uri.parse('zcash:u1addr?memo=SGVsbG8');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.memo, 'Hello');
      });

      test('memo and message are separate fields', () {
        final uri = Uri.parse('zcash:u1addr?amount=1.0&memo=SGVsbG8&message=local+note');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.memo, 'Hello');
        expect(paymentRequest.note, 'local note');
      });

      test('empty memo param results in null memo', () {
        final uri = Uri.parse('zcash:u1addr?memo=');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.memo, isNull);
      });

      test('non-zcash scheme does not parse memo', () {
        final uri = Uri.parse('bitcoin:bc1abc?memo=SGVsbG8');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.memo, isNull);
      });

      test('decode unicode memo (UTF-8 encoded)', () {
        // "Zcash !" base64url encoded
        // dart: base64Url.encode(utf8.encode("Zcash ❤️!")) = WmNhc2gg4p2k77iPIQ==
        // Let's use a simpler example: "café" = Y2Fmw6k=
        final uri = Uri.parse('zcash:u1addr?memo=Y2Fmw6k=');
        final paymentRequest = PaymentRequest.fromUri(uri);

        expect(paymentRequest.memo, 'café');
      });
    });
  });
}
