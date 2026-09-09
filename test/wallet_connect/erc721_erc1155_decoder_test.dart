import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc1155_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc721_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final resolver = StubErc20Resolver(const {});
  final erc721 = Erc721Decoder(resolver);
  final erc1155 = Erc1155Decoder(resolver);

  const collection = "0x1111111111111111111111111111111111111111";
  const from = "0x2222222222222222222222222222222222222222";
  const to = "0x3333333333333333333333333333333333333333";
  const operator = "0x4444444444444444444444444444444444444444";

  EvmCalldata call(String selector, String body) => EvmCalldata.parse("0x$selector$body")!;

  group("ERC-721", () {
    test("safeTransferFrom shows the token id and both parties", () {
      final decoded = erc721.decode(
        calldata: call("42842e0e", wordAddr(from) + wordAddr(to) + wordInt(1234)),
        contractAddress: collection,
      );
      expect(decoded, isNotNull);
      expect(decoded!.actionTitle, S.current.wc_action_nft_transfer);
      expect(decoded.actionSubtitle, "0x1111…1111");
      expect(decoded.rows.first.value, "#1234");
      expect(decoded.rows.any((r) => r.value == from), isTrue);
      expect(decoded.rows.any((r) => r.value == to), isTrue);
    });

    test("safeTransferFrom with data payload decodes the same fields", () {
      final decoded = erc721.decode(
        calldata: call("b88d4fde", wordAddr(from) + wordAddr(to) + wordInt(7)),
        contractAddress: collection,
      );
      expect(decoded!.rows.first.value, "#7");
    });

    test("setApprovalForAll warns when granting", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(1)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_set_approval_for_all);
      expect(decoded.warnings, contains(S.current.wc_warning_set_approval_for_all));
      expect(decoded.rows.single.value, operator);
    });

    test("setApprovalForAll revoking has no warning", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(0)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_revoke_approval_for_all);
      expect(decoded.warnings, isEmpty);
    });

    test("a non-boolean approval word is rejected rather than guessed", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(2)),
        contractAddress: collection,
      );
      expect(decoded, isNull);
    });

    test("unrelated selector returns null", () {
      expect(
        erc721.decode(calldata: call("deadbeef", wordInt(1)), contractAddress: collection),
        isNull,
      );
    });
  });

  group("ERC-1155", () {
    test("safeTransferFrom shows id and amount", () {
      final decoded = erc1155.decode(
        calldata: call(
          "f242432a",
          wordAddr(from) + wordAddr(to) + wordInt(9) + wordInt(3),
        ),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_nft_transfer);
      expect(decoded.rows.first.value, "#9");
      expect(decoded.rows.any((r) => r.value == "3"), isTrue);
    });

    test("safeBatchTransferFrom pairs every id with its amount", () {
      final body = wordAddr(from) +
          wordAddr(to) +
          wordInt(0xa0) +
          wordInt(0x100) +
          wordInt(0x160) +
          uintArrayBody([BigInt.one, BigInt.two]) +
          uintArrayBody([BigInt.from(5), BigInt.from(6)]);
      final decoded = erc1155.decode(
        calldata: call("2eb2c2d6", body),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_nft_batch_transfer);
      expect(decoded.rows.first.label, S.current.wc_token_id);
      expect(decoded.rows.first.value, "#1 ×5, #2 ×6");
    });

    test("a long batch is truncated with a remainder count", () {
      final ids = List.generate(9, (i) => BigInt.from(i + 1));
      final amounts = List.generate(9, (i) => BigInt.one);
      final body = wordAddr(from) +
          wordAddr(to) +
          wordInt(0xa0) +
          wordInt(0x1e0) +
          wordInt(0x320) +
          uintArrayBody(ids) +
          uintArrayBody(amounts);
      final decoded = erc1155.decode(
        calldata: call("2eb2c2d6", body),
        contractAddress: collection,
      );
      expect(decoded!.rows.first.value, contains(S.current.wc_plus_n_more("3")));
      expect(decoded.rows.first.value, startsWith("#1 ×1"));
    });

    test("a batch with unreadable arrays still shows the parties", () {
      final decoded = erc1155.decode(
        calldata: call("2eb2c2d6", wordAddr(from) + wordAddr(to)),
        contractAddress: collection,
      );
      expect(decoded, isNotNull);
      expect(decoded!.rows.any((r) => r.label == S.current.wc_token_id), isFalse);
      expect(decoded.rows.any((r) => r.value == to), isTrue);
    });
  });
}
