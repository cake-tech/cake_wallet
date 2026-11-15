import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

WalletContact _contact(
  String label, {
  String name = "Savings",
  CryptoCurrency type = CryptoCurrency.btc,
  WalletType walletType = WalletType.bitcoin,
}) =>
    WalletContact("address", name, type, walletType: walletType, label: label);

void main() {
  group("WalletContact.isPickable", () {
    test("offers the active address when its name is translated", () {
      final contact = _contact("Active", name: "Savings (Aktiv)");

      expect(contact.isPickable, isTrue);
    });

    test("hides a Bitcoin wallet's other address types", () {
      expect(_contact("P2WPKH").isPickable, isFalse);
      expect(_contact("LN").isPickable, isFalse);
      expect(_contact("Silent Payments").isPickable, isFalse);
    });

    test("ignores a wallet name that contains Active", () {
      final contact = _contact("P2TR", name: "Active Savings (P2TR)");

      expect(contact.isPickable, isFalse);
    });

    test("applies the same rule to Litecoin", () {
      final active = _contact("Active - P2WPKH", type: CryptoCurrency.ltc);
      final other = _contact("MWEB", type: CryptoCurrency.ltc);

      expect(active.isPickable, isTrue);
      expect(other.isPickable, isFalse);
    });

    test("leaves single-address currencies alone", () {
      final contact = _contact("", type: CryptoCurrency.eth, walletType: WalletType.ethereum);

      expect(contact.isPickable, isTrue);
    });
  });
}
