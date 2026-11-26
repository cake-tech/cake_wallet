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

  const erc721 = Erc721Decoder();
  const erc1155 = Erc1155Decoder();

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
      expect(decoded!.actionTitle, S.current.wc_action_nft_transfer);
      expect(decoded.actionSubtitle, "0x1111…1111");
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token_id, "#1234"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
    });

    test("safeTransferFrom with data payload decodes the same fields", () {
      final decoded = erc721.decode(
        calldata: call("b88d4fde", wordAddr(from) + wordAddr(to) + wordInt(7)),
        contractAddress: collection,
      );
      expect(rowLines(decoded!.rows), [
        row(S.current.wc_token_id, "#7"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
    });

    test("setApprovalForAll warns when granting", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(1)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_set_approval_for_all);
      expect(decoded.warnings, [S.current.wc_warning_set_approval_for_all]);
      expect(rowLines(decoded.rows), [row(S.current.wc_operator, operator)]);
    });

    test("setApprovalForAll revoking has no warning", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(0)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_revoke_approval_for_all);
      expect(rowLines(decoded.rows), [row(S.current.wc_operator, operator)]);
      expect(decoded.warnings, isEmpty);
    });

    test("any non-zero approval word grants, as collections built before Solidity 0.8 read it", () {
      final decoded = erc721.decode(
        calldata: call("a22cb465", wordAddr(operator) + wordInt(2)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_set_approval_for_all);
      expect(decoded.rows.single.value, operator);
      expect(decoded.warnings, [S.current.wc_warning_set_approval_for_all]);
    });

    test("unrelated selector returns null", () {
      expect(
        erc721.decode(calldata: call("deadbeef", wordInt(1)), contractAddress: collection),
        isNull,
      );
    });

    test("a setApprovalForAll cut short still names the operator it approves, and warns", () {
      final body = wordAddr(operator) + wordInt(0x0100);
      final decoded = erc721.decode(
        calldata: call("a22cb465", body.substring(0, body.length - 2)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_set_approval_for_all);
      expect(rowLines(decoded.rows), [row(S.current.wc_operator, operator)]);
      expect(decoded.warnings, [
        S.current.wc_warning_set_approval_for_all,
        S.current.wc_warning_decode_failed,
      ]);
    });

    test("a transfer cut short shows the token id an old collection reads", () {
      final body = wordAddr(from) + wordAddr(to) + wordInt(0x1234);
      for (final selector in ["42842e0e", "b88d4fde"]) {
        final decoded = erc721.decode(
          calldata: call(selector, body.substring(0, body.length - 2)),
          contractAddress: collection,
        );
        expect(rowLines(decoded!.rows), [
          row(S.current.wc_token_id, "#${0x1200}"),
          row(S.current.from, from),
          row(S.current.to, to),
        ], reason: selector);
        expect(decoded.warnings, [S.current.wc_warning_decode_failed], reason: selector);
      }
    });
  });

  group("ERC-1155", () {
    test("safeTransferFrom shows id and amount", () {
      final decoded = erc1155.decode(
        calldata: call("f242432a", wordAddr(from) + wordAddr(to) + wordInt(9) + wordInt(3)),
        contractAddress: collection,
      );
      expect(decoded!.actionTitle, S.current.wc_action_nft_transfer);
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token_id, "#9"),
        row(S.current.wc_amount, "3"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
    });

    test("safeBatchTransferFrom pairs every id with its amount", () {
      final body =
          wordAddr(from) +
          wordAddr(to) +
          wordInt(0xa0) +
          wordInt(0x100) +
          wordInt(0x160) +
          uintArrayBody([BigInt.one, BigInt.two]) +
          uintArrayBody([BigInt.from(5), BigInt.from(6)]);
      final decoded = erc1155.decode(calldata: call("2eb2c2d6", body), contractAddress: collection);
      expect(decoded!.actionTitle, S.current.wc_action_nft_batch_transfer);
      expect(rowLines(decoded.rows), [
        row(S.current.wc_token_id, "#1 ×5"),
        row(S.current.wc_token_id, "#2 ×6"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
    });

    test("a long batch lists every id with its amount", () {
      final ids = List.generate(9, (i) => BigInt.from(i + 1));
      final amounts = List.generate(9, (i) => BigInt.from(100 + i));
      final body =
          wordAddr(from) +
          wordAddr(to) +
          wordInt(0xa0) +
          wordInt(0x1e0) +
          wordInt(0x320) +
          uintArrayBody(ids) +
          uintArrayBody(amounts);
      final decoded = erc1155.decode(calldata: call("2eb2c2d6", body), contractAddress: collection);
      expect(rowLines(decoded!.rows), [
        for (var index = 0; index < 9; index++)
          row(S.current.wc_token_id, "#${index + 1} ×${100 + index}"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("a batch with unreadable arrays shows the parties and warns", () {
      final decoded = erc1155.decode(
        calldata: call("2eb2c2d6", wordAddr(from) + wordAddr(to)),
        contractAddress: collection,
      );
      expect(rowLines(decoded!.rows), [row(S.current.from, from), row(S.current.to, to)]);
      expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    });

    test("a batch naming more ids than amounts warns, the collection reverts it", () {
      final body =
          wordAddr(from) +
          wordAddr(to) +
          wordInt(0xa0) +
          wordInt(0x100) +
          wordInt(0x140) +
          uintArrayBody([BigInt.one, BigInt.two]) +
          uintArrayBody([BigInt.from(5)]);
      final decoded = erc1155.decode(calldata: call("2eb2c2d6", body), contractAddress: collection);
      expect(rowLines(decoded!.rows), [row(S.current.from, from), row(S.current.to, to)]);
      expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    });

    test("a single transfer cut short shows the amount an old collection reads", () {
      final body = wordAddr(from) + wordAddr(to) + wordInt(9) + wordInt(0x0301);
      final decoded = erc1155.decode(
        calldata: call("f242432a", body.substring(0, body.length - 2)),
        contractAddress: collection,
      );
      expect(rowLines(decoded!.rows), [
        row(S.current.wc_token_id, "#9"),
        row(S.current.wc_amount, "${0x0300}"),
        row(S.current.from, from),
        row(S.current.to, to),
      ]);
      expect(decoded.warnings, [S.current.wc_warning_decode_failed]);
    });
  });
}
