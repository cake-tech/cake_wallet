import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_request_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:flutter_test/flutter_test.dart";

import "abi_hex.dart";
import "stubs.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final decoder = EvmRequestDecoder(null);
  const router = "0x1111111111111111111111111111111111111111";
  const recipient = "0x2222222222222222222222222222222222222222";
  const sender = "0x3333333333333333333333333333333333333333";
  const attacker = "0x9999999999999999999999999999999999999999";
  const usdc = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const dai = "0x6b175474e89094c44da98b954eedeac495271d0f";
  final halfEth = BigInt.from(5) * BigInt.from(10).pow(17);

  String transferCalldata(String to, int amount) => "a9059cbb${wordAddr(to)}${wordInt(amount)}";

  test("no calldata decodes as a native send that owns its value row", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: null,
      toAddress: recipient,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: halfEth,
      chainId: 1,
    );
    expect(decoded.actionTitle, S.current.wc_action_send);
    expect(decoded.rows.first.value, "0.5 ETH");
    expect(decoded.rows.any((r) => r.value == recipient), isTrue);
    expect(decoded.isValueShown, isTrue);
  });

  test("unknown selector keeps the value visible and warns", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: "0xdeadbeef${wordInt(1)}",
      toAddress: router,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: halfEth,
      chainId: 1,
    );
    expect(decoded.actionTitle, S.current.wc_contract_call);
    expect(decoded.actionSubtitle, "0xdeadbeef");
    expect(decoded.warnings, contains(S.current.wc_warning_unknown_contract));
    expect(decoded.rows.any((r) => r.value == "0.5 ETH"), isTrue);
    expect(decoded.isValueShown, isTrue);
  });

  test("checksummed-case calldata still matches the selector", () async {
    final decoded = await decoder.decodeTransaction(
      rawData: "0x${transferCalldata(recipient, 42).toUpperCase()}",
      toAddress: router,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: BigInt.zero,
      chainId: 1,
    );
    expect(decoded.actionTitle, S.current.wc_action_transfer);
  });

  test("calldata with no contract to call is never read as a token or NFT call", () async {
    final nftTransfer = "42842e0e${wordAddr(sender)}${wordAddr(recipient)}${wordInt(7)}";
    final batchTransfer =
        "2eb2c2d6${wordAddr(sender)}${wordAddr(recipient)}${wordInt(0xa0)}${wordInt(0xe0)}"
        "${wordInt(0x120)}${uintArrayBody([BigInt.one])}${uintArrayBody([BigInt.two])}"
        "${wordInt(0)}";

    for (final calldata in [nftTransfer, batchTransfer, transferCalldata(recipient, 42)]) {
      final decoded = await decoder.decodeTransaction(
        rawData: "0x$calldata",
        toAddress: null,
        fromAddress: sender,
        nativeSymbol: "ETH",
        valueWei: BigInt.zero,
        chainId: 1,
      );
      expect(decoded.actionTitle, S.current.wc_contract_call, reason: calldata);
      expect(decoded.warnings, [S.current.wc_warning_unknown_contract], reason: calldata);
    }
  });

  test("an approve cut short is not the blind contract-call view", () async {
    final max = (BigInt.one << 256) - BigInt.one;
    final approve = "095ea7b3${wordAddr(recipient)}${word(max)}";
    final decoded = await decoder.decodeTransaction(
      rawData: "0x${approve.substring(0, approve.length - 2)}",
      toAddress: usdc,
      fromAddress: sender,
      nativeSymbol: "ETH",
      valueWei: BigInt.zero,
      chainId: 1,
    );
    expect(decoded.actionTitle, S.current.wc_action_approve);
    expect(rowValue(decoded.rows, S.current.wc_approved_spender), recipient);
    expect(decoded.warnings, [
      S.current.wc_warning_unlimited_approval,
      S.current.wc_warning_unknown_token,
      S.current.wc_warning_decode_failed,
    ]);
  });

  group("a token, NFT or permit call that carries value", () {
    const mainnetWeth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
    const permit2 = "0x000000000022d473030f116ddee9f6b43ac78ba3";
    final toSelfAndAmount = "${wordAddr(sender)}${wordAddr(sender)}${wordInt(1)}";
    final spenderAndAmount = "${wordAddr(recipient)}${wordInt(5)}";
    final emptyBytes = wordInt(0);
    final calls = [
      ("transfer", transferCalldata(sender, 1), attacker),
      ("approve", "095ea7b3$spenderAndAmount", attacker),
      ("transferFrom", "23b872dd$toSelfAndAmount", attacker),
      ("increaseAllowance", "39509351$spenderAndAmount", attacker),
      ("decreaseAllowance", "a457c2d7$spenderAndAmount", attacker),
      ("safeTransferFrom", "42842e0e$toSelfAndAmount", attacker),
      ("safeTransferFrom(bytes)", "b88d4fde$toSelfAndAmount${wordInt(0x80)}$emptyBytes", attacker),
      ("setApprovalForAll", "a22cb465${wordAddr(recipient)}${wordInt(0)}", attacker),
      (
        "safeTransferFrom",
        "f242432a$toSelfAndAmount${wordInt(2)}${wordInt(0xa0)}$emptyBytes",
        attacker,
      ),
      (
        "safeBatchTransferFrom",
        "2eb2c2d6${wordAddr(sender)}${wordAddr(sender)}${wordInt(0xa0)}${wordInt(0xe0)}"
            "${wordInt(0x120)}${uintArrayBody([BigInt.one])}${uintArrayBody([BigInt.two])}"
            "$emptyBytes",
        attacker,
      ),
      (
        "permit",
        "d505accf${wordAddr(sender)}$spenderAndAmount${wordInt(1791460959)}${wordInt(27)}"
            "${wordInt(1)}${wordInt(2)}",
        attacker,
      ),
      (
        "permit2",
        "2b67b570${wordAddr(sender)}${wordAddr(usdc)}${wordInt(7)}${wordInt(1791460959)}"
            "${wordInt(0)}${wordAddr(recipient)}${wordInt(1791460960)}${wordInt(0x100)}"
            "$emptyBytes",
        permit2,
      ),
      ("permit2Batch", "2a2d80d1${wordAddr(sender)}", permit2),
      (
        "permit2PermitTransferFrom",
        "30f28b7a${wordAddr(usdc)}${wordInt(7)}${wordInt(0)}${wordInt(1791460959)}"
            "${wordAddr(sender)}${wordInt(6)}${wordAddr(sender)}${wordInt(0x100)}$emptyBytes",
        permit2,
      ),
      (
        "permit2TransferFrom",
        "36c78516${wordAddr(sender)}${wordAddr(sender)}${wordInt(7)}${wordAddr(usdc)}",
        permit2,
      ),
    ];

    Future<WCDecodedRequest> decode(String calldata, String to, BigInt value) =>
        decoder.decodeTransaction(
          rawData: "0x$calldata",
          toAddress: to,
          fromAddress: sender,
          nativeSymbol: "ETH",
          valueWei: value,
          chainId: 1,
        );

    test("is a call that pays the contract, whatever the calldata says it does", () async {
      for (final (name, calldata, contract) in calls) {
        final withoutValue = await decode(calldata, contract, BigInt.zero);
        expect(withoutValue.actionTitle, isNot(S.current.wc_contract_call), reason: name);

        final withValue = await decode(calldata, contract, halfEth);
        expect(withValue.actionTitle, S.current.wc_contract_call, reason: name);
        expect(withValue.actionSubtitle, name);
        expect(rowLines(withValue.rows), [
          row(S.current.wc_contract, contract),
          row(S.current.wc_value, "0.5 ETH"),
        ], reason: name);
        expect(withValue.warnings, [S.current.wc_warning_unknown_contract], reason: name);
      }
    });

    test("a wrap is paid in value and keeps its own view", () async {
      final wrap = await decode("d0e30db0", mainnetWeth, halfEth);
      expect(wrap.actionTitle, S.current.wc_action_wrap("ETH"));
      expect(wrap.isValueShown, isFalse);
      expect(wrap.warnings, isEmpty);

      final unwrap = await decode("2e1a7d4d${wordInt(5)}", mainnetWeth, halfEth);
      expect(unwrap.actionTitle, S.current.wc_contract_call);
      expect(rowLines(unwrap.rows), contains(row(S.current.wc_value, "0.5 ETH")));
    });

    test("a multicall still reads its steps under the one value row", () async {
      final multicall = "ac9650d8${wordInt(0x20)}${bytesArrayBody([transferCalldata(sender, 1)])}";
      final decoded = await decode(multicall, attacker, halfEth);
      expect(decoded.actionTitle, S.current.wc_contract_call);
      expect(rowLines(decoded.rows), [
        row(S.current.wc_contract, attacker),
        row(S.current.wc_value, "0.5 ETH"),
        row(S.current.wc_step_n("1"), S.current.wc_action_transfer),
        row(S.current.wc_token, attacker),
        row(S.current.wc_amount, "1 0x9999…9999"),
        row(S.current.to, sender),
      ]);
    });
  });

  group("calldata shorter than a selector", () {
    for (final shortCalldata in ["0xab", "0xabcd", "0xabcdef"]) {
      test("$shortCalldata calls the contract's fallback, it is not a plain send", () async {
        final decoded = await decoder.decodeTransaction(
          rawData: shortCalldata,
          toAddress: router,
          fromAddress: sender,
          nativeSymbol: "ETH",
          valueWei: halfEth,
          chainId: 1,
        );
        expect(decoded.actionTitle, S.current.wc_contract_call);
        expect(decoded.actionSubtitle, shortCalldata);
        expect(rowLines(decoded.rows), [
          row(S.current.wc_contract, router),
          row(S.current.wc_value, "0.5 ETH"),
        ]);
        expect(decoded.warnings, [S.current.wc_warning_unknown_contract]);
      });
    }

    test("empty calldata is still a native send", () async {
      final decoded = await decoder.decodeTransaction(
        rawData: "0x",
        toAddress: recipient,
        fromAddress: sender,
        nativeSymbol: "ETH",
        valueWei: halfEth,
        chainId: 1,
      );
      expect(decoded.actionTitle, S.current.wc_action_send);
    });
  });

  group("multicall", () {
    String multicall(List<String> calls) => "0xac9650d8${wordInt(0x20)}${bytesArrayBody(calls)}";

    String multicallWithDeadline(List<String> calls, {BigInt? deadline}) =>
        "0x5ae401dc${word(deadline ?? BigInt.from(1700000000))}${wordInt(0x40)}"
        "${bytesArrayBody(calls)}";

    Future<WCDecodedRequest> decode(String rawData, {BigInt? value, String to = router}) =>
        decoder.decodeTransaction(
          rawData: rawData,
          toAddress: to,
          fromAddress: sender,
          nativeSymbol: "ETH",
          valueWei: value ?? BigInt.zero,
          chainId: 1,
        );

    test("single inner call surfaces as the inner decode plus deadline", () async {
      final decoded = await decode(multicallWithDeadline([transferCalldata(recipient, 42)]));
      expect(decoded.actionTitle, S.current.wc_action_transfer);
      expect(decoded.rows.last.label, S.current.wc_deadline);
      expect(decoded.rows.any((r) => r.value == recipient), isTrue);
    });

    test("a deadline past the year 9999 reads as never", () async {
      final calls = [transferCalldata(recipient, 42)];
      final dated = await decode(multicallWithDeadline(calls));
      expect(dated.rows.last.value, decoder.tokenResolver.formatTimestamp(BigInt.from(1700000000)));

      final uint256Max = (BigInt.one << 256) - BigInt.one;
      final openEnded = await decode(multicallWithDeadline(calls, deadline: uint256Max));
      expect(openEnded.rows.last.label, S.current.wc_deadline);
      expect(openEnded.rows.last.value, S.current.wc_never);
    });

    test("several inner calls put every step on the main card", () async {
      final decoded = await decode(
        multicall([transferCalldata(recipient, 42), "deadbeef${wordInt(1)}"]),
      );
      expect(decoded.actionTitle, S.current.wc_contract_call);
      expect(decoded.actionSubtitle, "multicall");
      expect(rowLines(decoded.rows), [
        row(S.current.wc_contract, router),
        row(S.current.wc_step_n("1"), S.current.wc_action_transfer),
        row(S.current.wc_token, router),
        row(S.current.wc_amount, "42 0x1111…1111"),
        row(S.current.to, recipient),
        row(S.current.wc_step_n("2"), "0xdeadbeef"),
      ]);
      expect(decoded.detailRows, isEmpty);
      expect(decoded.warnings, [
        S.current.wc_warning_decode_failed,
        S.current.wc_warning_unknown_contract,
        S.current.wc_warning_unknown_token,
      ]);
    });

    test("more than one decoded step warns that the request does more than one thing", () async {
      Future<WCDecodedRequest> transfersTo(String first, String second) => decode(
        multicall([transferCalldata(first, 42), transferCalldata(second, 43)]),
        value: halfEth,
      );

      for (final decoded in [
        await transfersTo(recipient, attacker),
        await transfersTo(attacker, recipient),
      ]) {
        expect(
          rowLines(decoded.rows),
          containsAll([row(S.current.to, recipient), row(S.current.to, attacker)]),
        );
        expect(decoded.warnings, [
          S.current.wc_warning_swap_extra_transfers,
          S.current.wc_warning_unknown_contract,
          S.current.wc_warning_unknown_token,
        ]);
      }
    });

    test("the transaction value is shown once, no step claims it", () async {
      const mainnetWeth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
      final swap =
          "04e45aaf${wordAddr(mainnetWeth)}${wordAddr(usdc)}${wordInt(500)}${wordAddr(sender)}"
          "${word(halfEth)}${wordInt(1)}${wordInt(0)}";
      final decoded = await decode(multicall([swap, "deadbeef${wordInt(1)}"]), value: halfEth);
      final valueRows = rowLines(decoded.rows).where((shown) => shown.endsWith("0.5 ETH"));
      expect(valueRows, [row(S.current.wc_value, "0.5 ETH")]);
      expect(
        rowLines(decoded.rows),
        contains(row(S.current.wc_swap_from, "500000000000000000 0xc02a…6cc2")),
      );
    });

    test("a swap router payment among other calls names who it pays", () async {
      final decoded = await decode(
        multicall([
          transferCalldata(recipient, 42),
          "49404b7c${word(halfEth)}${wordAddr(attacker)}",
        ]),
      );
      expect(rowLines(decoded.rows), [
        row(S.current.wc_contract, router),
        row(S.current.wc_step_n("1"), S.current.wc_action_transfer),
        row(S.current.wc_token, router),
        row(S.current.wc_amount, "42 0x1111…1111"),
        row(S.current.to, recipient),
        row(S.current.wc_step_n("2"), "unwrapWETH9"),
        row(S.current.wc_swap_to_min, "0.5 ETH"),
        row(S.current.wc_recipient, attacker),
        row(S.current.wc_router, router),
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_swap_extra_transfers,
        S.current.wc_warning_unknown_contract,
        S.current.wc_warning_unknown_token,
        S.current.wc_warning_decode_failed,
        S.current.wc_warning_recipient_not_you,
      ]);
    });

    test("every step is listed with who it pays, however many come before it", () async {
      final decoded = await decode(
        multicall([
          for (var i = 0; i < 12; i++) transferCalldata(recipient, 100 + i),
          transferCalldata(attacker, 5000),
          "49404b7c${word(halfEth)}${wordAddr(sender)}",
        ]),
      );
      final amounts = decoded.rows.where((r) => r.label == S.current.wc_amount);
      expect(amounts.map((r) => r.value).toList(), [
        for (var i = 0; i < 12; i++) "${100 + i} 0x1111…1111",
        "5000 0x1111…1111",
      ]);
      expect(rowLines(decoded.rows).skip(rowLines(decoded.rows).length - 8), [
        row(S.current.wc_step_n("13"), S.current.wc_action_transfer),
        row(S.current.wc_token, router),
        row(S.current.wc_amount, "5000 0x1111…1111"),
        row(S.current.to, attacker),
        row(S.current.wc_step_n("14"), "unwrapWETH9"),
        row(S.current.wc_swap_to_min, "0.5 ETH"),
        row(S.current.wc_recipient, S.current.wc_recipient_you),
        row(S.current.wc_router, router),
      ]);
    });

    test(
      "an unread call on a listed router warns about the call, not about the contract",
      () async {
        const swapRouter02 = "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45";
        final decoded = await decode(
          multicall([transferCalldata(recipient, 42), "deadbeef${wordInt(1)}"]),
          to: swapRouter02,
        );
        expect(decoded.warnings, [
          S.current.wc_warning_decode_failed,
          S.current.wc_warning_unknown_token,
        ]);
      },
    );

    group("of swaps on SwapRouter02", () {
      const swapRouter02 = "0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45";
      String exactInputSingle(String swapRecipient, int amountIn, int amountOutMinimum) =>
          "04e45aaf${wordAddr(usdc)}${wordAddr(dai)}${wordInt(500)}${wordAddr(swapRecipient)}"
          "${wordInt(amountIn)}${wordInt(amountOutMinimum)}${wordInt(0)}";

      test("two swaps to two recipients are both listed, in either order", () async {
        final toWallet = exactInputSingle(sender, 100, 99);
        final toAttacker = exactInputSingle(attacker, 100000, 1);

        final walletLeg = [
          row(S.current.wc_swap_from, "100 0xa0b8…eb48"),
          row(S.current.wc_recipient, S.current.wc_recipient_you),
        ];
        final attackerLeg = [
          row(S.current.wc_swap_from, "100000 0xa0b8…eb48"),
          row(S.current.wc_recipient, attacker),
        ];

        for (final (calls, legs) in [
          ([toWallet, toAttacker], [...walletLeg, ...attackerLeg]),
          ([toAttacker, toWallet], [...attackerLeg, ...walletLeg]),
        ]) {
          final decoded = await decode(multicallWithDeadline(calls), to: swapRouter02);
          expect(decoded.actionTitle, S.current.wc_contract_call);
          expect(rowLines(decoded.rows), containsAllInOrder(legs));
          expect(decoded.rows.last.label, S.current.wc_deadline);
          expect(decoded.detailRows, isEmpty);
          expect(decoded.warnings, [
            S.current.wc_warning_decode_failed,
            S.current.wc_warning_unknown_token,
            S.current.wc_warning_recipient_not_you,
          ]);
        }
      });

      test("unwrapWETH9 is part of the swap, not an unknown step", () async {
        const mainnetWeth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
        final toRouter =
            "04e45aaf${wordAddr(usdc)}${wordAddr(mainnetWeth)}${wordInt(500)}"
            "${wordAddr("0x0000000000000000000000000000000000000002")}"
            "${wordInt(100)}${wordInt(0)}${wordInt(0)}";
        Future<WCDecodedRequest> unwrapTo(String unwrapRecipient) => decode(
          multicallWithDeadline([toRouter, "49404b7c${word(halfEth)}${wordAddr(unwrapRecipient)}"]),
          to: swapRouter02,
        );

        final toWallet = await unwrapTo(sender);
        expect(toWallet.actionTitle, S.current.wc_action_swap);
        expect(
          rowLines(toWallet.rows),
          containsAll([
            row(S.current.wc_swap_to_min, "0.5 ETH"),
            row(S.current.wc_recipient, S.current.wc_recipient_you),
          ]),
        );
        expect(toWallet.warnings, [S.current.wc_warning_unknown_token]);

        final toAttacker = await unwrapTo(attacker);
        expect(toAttacker.actionTitle, S.current.wc_contract_call);
        expect(
          rowLines(toAttacker.rows),
          containsAllInOrder([
            row(S.current.wc_swap_to_min, "0.5 ETH"),
            row(S.current.wc_recipient, attacker),
          ]),
        );
        expect(toAttacker.warnings, [
          S.current.wc_warning_decode_failed,
          S.current.wc_warning_unknown_token,
          S.current.wc_warning_recipient_not_you,
        ]);
      });
    });
  });
}
