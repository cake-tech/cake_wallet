import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/wallet_admin_decoder.dart";
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
    test("labels the target chain id distinctly from the session chain", () {
      final decoded = decoder.decodeSwitchChain([
        {"chainId": "0x89"},
      ]);
      expect(decoded.actionTitle, S.current.wc_action_switch_chain);
      final idRow = decoded.rows.firstWhere((r) => r.value == "137");
      expect(idRow.label, S.current.wc_target_chain_id);
      expect(decoded.hideTo, isTrue);
    });

    test("an unresolvable chain still shows its id and warns", () {
      final decoded = decoder.decodeSwitchChain([
        {"chainId": "0x5f5e0ff"},
      ]);
      expect(decoded.warnings, contains(S.current.wc_warning_chain_not_supported));
      expect(decoded.rows.any((r) => r.value == "99999999"), isTrue);
    });

    test("a missing chain id renders a placeholder rather than throwing", () {
      final decoded = decoder.decodeSwitchChain(const []);
      expect(decoded.rows.single.value, "?");
      expect(decoded.warnings, contains(S.current.wc_warning_chain_not_supported));
    });
  });

  group("decodeAddChain", () {
    test("surfaces the proposed chain name, currency, rpc and explorer", () {
      final decoded = decoder.decodeAddChain([
        {
          "chainId": "0x38",
          "chainName": "BNB Smart Chain",
          "nativeCurrency": {"name": "BNB", "symbol": "BNB", "decimals": 18},
          "rpcUrls": ["https://bsc-dataseed.example"],
          "blockExplorerUrls": ["https://bscscan.example"],
        }
      ]);
      expect(decoded.actionTitle, S.current.wc_action_add_chain);
      expect(decoded.actionSubtitle, "BNB Smart Chain");
      expect(decoded.rows.any((r) => r.value == "BNB Smart Chain"), isTrue);
      expect(decoded.rows.any((r) => r.value == "56"), isTrue);
      expect(decoded.rows.any((r) => r.value == "BNB (BNB)"), isTrue);
      expect(decoded.rows.any((r) => r.value == "https://bsc-dataseed.example"), isTrue);
      expect(decoded.rows.any((r) => r.value == "https://bscscan.example"), isTrue);
    });

    test("an empty config warns instead of rendering blanks", () {
      final decoded = decoder.decodeAddChain(const []);
      expect(decoded.rows, isEmpty);
      expect(decoded.warnings, contains(S.current.wc_warning_add_chain_not_supported));
    });

    test("a partial config omits the rows it has no data for", () {
      final decoded = decoder.decodeAddChain([
        {"chainId": "0x2329", "chainName": "Private Net"},
      ]);
      expect(decoded.rows.any((r) => r.value == "Private Net"), isTrue);
      expect(decoded.rows.any((r) => r.label == S.current.wc_new_rpc), isFalse);
      expect(decoded.rows.any((r) => r.label == S.current.wc_explorer), isFalse);
    });
  });
}
