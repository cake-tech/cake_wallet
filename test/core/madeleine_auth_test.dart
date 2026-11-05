import "dart:convert";

import "package:cake_wallet/core/madeleine_auth.dart";
import "package:convert/convert.dart";
import "package:crypto/crypto.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

const _secret = "test-secret";
const _address = "test-address";

class MockWallet extends Mock implements WalletBase {}

class MockWalletAddresses extends Mock implements WalletAddresses {}

String _hmac(String message) =>
    hex.encode(Hmac(sha256, utf8.encode(_secret)).convert(utf8.encode(message)).bytes);

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

void main() {
  group("MadeleineAuth", () {
    test("AuthLight", () {
      const path = "/api/moonpay/payment-methods";

      final now = _nowSeconds();
      final headers = const MadeleineAuth(useSandbox: true, secret: _secret)
          .getLightHeaders(method: "GET", path: path);

      final validUntil = int.parse(headers["X-Madeleine-Valid-Until"]!);
      expect(validUntil, inInclusiveRange(now + 10, now + 12));

      expect(headers, {
        "X-Madeleine-Valid-Until": "$validUntil",
        "X-Madeleine-Mac": _hmac("Madeleine Light Auth v1:\nGET $path $validUntil"),
        "x-madeleine-sandbox": "true",
      });
    });

    test("AuthFull", () async {
      const path = "/api/moonpay";

      final wallet = MockWallet();
      final walletAddresses = MockWalletAddresses();
      when(() => wallet.walletAddresses).thenReturn(walletAddresses);
      when(() => walletAddresses.address).thenReturn(_address);
      when(() => wallet.signMessage(any(), address: any(named: "address")))
          .thenAnswer((_) async => "test-signature");

      final now = _nowSeconds();
      final headers = await const MadeleineAuth(useSandbox: true, secret: _secret)
          .getFullHeaders(method: "POST", path: path, wallet: wallet);

      final validUntil = int.parse(headers["X-Madeleine-Valid-Until"]!);
      expect(validUntil, inInclusiveRange(now + 200, now + 202));

      verify(
        () => wallet.signMessage(
          "Madeleine Auth v1:\nPOST $path $_address $validUntil",
          address: _address,
        ),
      ).called(1);

      expect(headers, {
        "X-Madeleine-Signature": "test-signature",
        "X-Madeleine-Mac": "65af7aabc13fe1419dc07ba0d118bcb6ad61a3accd3c7ea59f957a22ca8a16f5",
        "X-Madeleine-Valid-Until": "$validUntil",
        "X-Madeleine-Wallet": _address,
        "x-madeleine-sandbox": "true",
      });
    });
  });
}
