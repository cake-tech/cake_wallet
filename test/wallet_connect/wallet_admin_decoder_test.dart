import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/wallet_admin_decoder.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = WalletAdminDecoder();

  group("extractChainId", () {
    test("reads hex and decimal forms from a params list or map", () {
      expect(
        decoder.extractChainId([
          {"chainId": "0x89"},
        ]),
        137,
      );
      expect(decoder.extractChainId({"chainId": "0x1"}), 1);
      expect(
        decoder.extractChainId([
          {"chainId": "137"},
        ]),
        137,
        reason: "an unprefixed chain id is decimal, reading it as hex would give 311",
      );
    });

    test("returns null when the params carry no chain id", () {
      expect(decoder.extractChainId(const []), isNull);
      expect(decoder.extractChainId(null), isNull);
      expect(
        decoder.extractChainId([
          {"other": "value"},
        ]),
        isNull,
      );
    });
  });

  group("decodeSwitchChain", () {
    test("names the target chain and its id", () {
      final decoded = decoder.decodeSwitchChain(
        const ChainInfo(
          chainId: 137,
          name: "Polygon",
          shortCode: "POL",
          currency: CryptoCurrency.maticpoly,
        ),
      );

      expect(decoded.actionTitle, S.current.wc_action_switch_chain);
      expect(decoded.actionSubtitle, "Polygon");
      expect(decoded.rows.map((row) => [row.label, row.value]), [
        [S.current.wc_target_chain, "Polygon"],
        [S.current.wc_target_chain_id, "137"],
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("a reason takes the place of the chain name under the title", () {
      final decoded = decoder.decodeSwitchChain(
        const ChainInfo(
          chainId: 8453,
          name: "Base",
          shortCode: "BASE",
          currency: CryptoCurrency.baseEth,
        ),
        reason: "This request is for Base.",
      );

      expect(decoded.actionSubtitle, "This request is for Base.");
      expect(decoded.rows.map((row) => row.value), ["Base", "8453"]);
    });
  });
}
