import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_source.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() => S.current = S());

  final wallet = WalletInfo.external(
    id: "id-btc",
    name: "Savings",
    type: WalletType.bitcoin,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  );

  group("ExternalSwapSource", () {
    test("is shown as external", () {
      expect(const ExternalSwapSource("").displayName, S.current.external);
    });

    test("withAddress sets the refund address", () {
      expect(const ExternalSwapSource("").withAddress("bc1qrefund").refundAddress, "bc1qrefund");
    });
  });

  group("InternalSwapSource", () {
    test("is shown by its wallet's name", () {
      expect(InternalSwapSource(wallet).displayName, "Savings");
    });

    test("has no refund address until one is picked", () {
      expect(InternalSwapSource(wallet).refundAddress, isNull);
    });

    test("withAddress keeps the wallet and sets the refund address", () {
      final source = InternalSwapSource(wallet).withAddress("bc1qrefund");

      expect(source.sourceWallet, same(wallet));
      expect(source.refundAddress, "bc1qrefund");
    });

    test("withAddress null goes back to the wallet's own address", () {
      expect(
        InternalSwapSource(wallet, refundAddress: "bc1qrefund").withAddress(null).refundAddress,
        isNull,
      );
    });
  });
}
