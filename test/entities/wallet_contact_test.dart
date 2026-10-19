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

      expect(contact.isPickable(includeSilentPayments: false), isTrue);
    });

    test("hides a Bitcoin wallet's other address types", () {
      expect(_contact("P2WPKH").isPickable(includeSilentPayments: true), isFalse);
      expect(_contact("LN").isPickable(includeSilentPayments: true), isFalse);
    });

    test("ignores a wallet name that contains Active", () {
      final contact = _contact("P2TR", name: "Active Savings (P2TR)");

      expect(contact.isPickable(includeSilentPayments: false), isFalse);
    });

    test("offers an active Silent Payments address only to senders that can pay it", () {
      final contact = _contact("Active - Silent Payments");

      expect(contact.isPickable(includeSilentPayments: true), isTrue);
      expect(contact.isPickable(includeSilentPayments: false), isFalse);
    });

    test("never offers an inactive Silent Payments address", () {
      expect(_contact("Silent Payments").isPickable(includeSilentPayments: true), isFalse);
      expect(
        _contact("Silent Payments - Active stash").isPickable(includeSilentPayments: true),
        isFalse,
      );
    });

    test("applies the same rule to Litecoin", () {
      final active = _contact("Active - MWEB", type: CryptoCurrency.ltc);
      final other = _contact("P2WPKH", type: CryptoCurrency.ltc);

      expect(active.isPickable(includeSilentPayments: false), isTrue);
      expect(other.isPickable(includeSilentPayments: false), isFalse);
    });

    test("leaves single-address currencies alone", () {
      final contact = _contact("", type: CryptoCurrency.eth, walletType: WalletType.ethereum);

      expect(contact.isPickable(includeSilentPayments: false), isTrue);
    });
  });
}
