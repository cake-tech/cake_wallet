import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PivxFeePolicy', () {
    test('uses one transparent fee and dust policy', () {
      expect(PivxFeePolicy.transparentDustThreshold, 5460);
      expect(PivxFeePolicy.shieldedDustThreshold, 1446000);
      expect(PivxFeePolicy.feeForSize(182), 10000);
      expect(
        PivxFeePolicy.feeForSize(
          182,
          feePerKb: PivxFeePolicy.dustRelayFeePerKb,
        ),
        5460,
      );
      // Sized for an EXM output (35 bytes), the largest transparent output.
      expect(PivxFeePolicy.transparentTxSize(1, 1), 193);
      // Same IsDust formula over the 35-byte exchange output.
      expect(
        PivxFeePolicy.feeForSize(
          PivxFeePolicy.transparentOutputSize +
              PivxFeePolicy.transparentInputSize,
          feePerKb: PivxFeePolicy.dustRelayFeePerKb,
        ),
        PivxFeePolicy.exchangeDustThreshold,
      );
    });

    test('calculates Sapling fees from transaction size', () {
      // A single real shielded output is padded to the 2-output minimum, so a
      // 1-spend/1-output tx pays for two 948-byte outputs.
      expect(
        PivxFeePolicy.saplingFee(saplingInputs: 1, saplingOutputs: 1),
        2365000,
      );
      // Two real outputs are already at the minimum; counted as-is.
      expect(
        PivxFeePolicy.saplingFee(saplingInputs: 1, saplingOutputs: 2),
        2365000,
      );
      // A third real output is counted as-is.
      expect(
        PivxFeePolicy.saplingFee(saplingInputs: 1, saplingOutputs: 3),
        3313000,
      );
    });

    test('pads shielded outputs to the 2-output minimum for the deshield fee',
        () {
      // z->t: 1 spend + 1 shielded change + 1 transparent output. The builder
      // pads the change to two shielded outputs, so the fee must cover both or
      // the node rejects it as "insufficient fee" (the reported 1451000 <
      // 2399000). 85 + 384 + 2*948 + 35 = 2400 bytes -> 2_400_000 zat; the
      // transparent output is sized for EXM, one byte over the 2399 minimum.
      expect(
        PivxFeePolicy.saplingFee(
            saplingInputs: 1, saplingOutputs: 1, transparentOutputs: 1),
        2400000,
      );
    });

    test('sizes the CompactSize count prefix so the fee is an exact upper '
        'bound past 253 inputs', () {
      // Below 253 elements every vector count is a 1-byte CompactSize; a single
      // real shielded output is padded to the 2-output minimum.
      expect(PivxFeePolicy.saplingTxSize(saplingInputs: 1, saplingOutputs: 1),
          85 + 384 + 2 * 948);
      expect(PivxFeePolicy.saplingTxSize(saplingInputs: 252, saplingOutputs: 1),
          85 + 252 * 384 + 2 * 948);
      // At 253 spends the count prefix grows to 3 bytes (+2). Without this the
      // estimate under-counts the real tx by 2 bytes and the pinned fee is 2000
      // zat short: the network rejects a big sweep as "insufficient fee".
      expect(
        PivxFeePolicy.saplingTxSize(saplingInputs: 253, saplingOutputs: 1) -
            PivxFeePolicy.saplingTxSize(saplingInputs: 252, saplingOutputs: 1),
        384 + 2,
      );
    });

    test('derives shielded dust threshold from PIVX Core formula', () {
      // PIVX Core policy.cpp GetShieldedDustThreshold uses its fixed
      // CTXOUT_REGULAR_SIZE (a P2PKH output), not the wallet's fee estimate.
      const coreRegularTxOutSize = 34;
      final coreShieldedDust = PivxFeePolicy.saplingFeeFactor *
          PivxFeePolicy.feeForSize(
            PivxFeePolicy.saplingSpendSize + coreRegularTxOutSize + 64,
            feePerKb: PivxFeePolicy.dustRelayFeePerKb,
          );

      expect(coreShieldedDust, 1446000);
      expect(PivxFeePolicy.shieldedDustThreshold, coreShieldedDust);
    });
  });

  group('SaplingTransactionBuilder note planning', () {
    test('selects enough notes to cover amount and fee', () {
      final selected = SaplingTransactionBuilder.selectNotesForAmount(
        [
          {'value': 3000000},
          {'value': 500000},
        ],
        2000000,
      );

      expect(selected.length, 2);
    });

    test('deducts dust change into fee instead of creating dust output', () {
      final noChangeFee =
          PivxFeePolicy.saplingFee(saplingInputs: 1, saplingOutputs: 1);
      const dustRemainder = 9000;
      final plan = SaplingTransactionBuilder.planShieldedSpend(
        totalInput: 2000000 + noChangeFee + dustRemainder,
        amount: 2000000,
        saplingInputs: 1,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, 0);
      expect(plan.fee, noChangeFee + dustRemainder);
    });

    test('send-all takes every note, not just enough to pay', () {
      final notes = [
        {'value': 30000000},
        {'value': 500000},
      ];
      // 0.00000001 PIV is covered by the first note alone, so only spendAll
      // adds the second.
      expect(SaplingTransactionBuilder.selectNotesForAmount(notes, 1).length, 1);
      expect(
          SaplingTransactionBuilder.selectNotesForAmount(notes, 1,
                  spendAll: true)
              .length,
          2);
    });

    test('z-to-t spend plan uses transparent destination output size', () {
      // 1 spend + 1 transparent vout; the shielded side is padded to the
      // 2-output minimum: size = 85 + 384 + 2*948 + 35 = 2400 -> fee 2_400_000.
      final expectedNoChangeFee = PivxFeePolicy.saplingFee(
        saplingInputs: 1,
        saplingOutputs: 0,
        transparentOutputs: 1,
      );
      final plan = SaplingTransactionBuilder.planShieldedSpend(
        totalInput: 2000000 + expectedNoChangeFee,
        amount: 2000000,
        saplingInputs: 1,
        transparentDestination: true,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, 0);
      expect(plan.fee, expectedNoChangeFee);
      // With output padding both shapes carry two shielded outputs, so the
      // deshield costs more than a shielded->shielded spend by its extra
      // transparent output.
      expect(
          expectedNoChangeFee,
          greaterThan(
              PivxFeePolicy.saplingFee(saplingInputs: 1, saplingOutputs: 1)));
    });

    test('z-to-t spend plan pays shielded change above dust', () {
      final withChangeFee = PivxFeePolicy.saplingFee(
        saplingInputs: 1,
        saplingOutputs: 1,
        transparentOutputs: 1,
      );
      final change = PivxFeePolicy.shieldedDustThreshold + 1;
      final plan = SaplingTransactionBuilder.planShieldedSpend(
        totalInput: 2000000 + withChangeFee + change,
        amount: 2000000,
        saplingInputs: 1,
        transparentDestination: true,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, change);
      expect(plan.fee, withChangeFee);
    });

    test('t-to-z shield plan pays transparent change above dust', () {
      final withChangeFee = PivxFeePolicy.saplingFee(
        saplingOutputs: 1,
        transparentInputs: 2,
        transparentOutputs: 1,
      );
      final change = PivxFeePolicy.transparentDustThreshold + 1;
      final plan = SaplingTransactionBuilder.planShieldSpend(
        totalInput: 2000000 + withChangeFee + change,
        amount: 2000000,
        transparentInputs: 2,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, change);
      expect(plan.fee, withChangeFee);
    });

    test('t-to-z shield plan absorbs dust change into the fee', () {
      final noChangeFee = PivxFeePolicy.saplingFee(
        saplingOutputs: 1,
        transparentInputs: 1,
      );
      final dust = PivxFeePolicy.transparentDustThreshold;
      final plan = SaplingTransactionBuilder.planShieldSpend(
        totalInput: 2000000 + noChangeFee + dust,
        amount: 2000000,
        transparentInputs: 1,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, 0);
      expect(plan.fee, noChangeFee + dust);
    });

    test('z-to-t dust change is absorbed into the fee', () {
      final noChangeFee = PivxFeePolicy.saplingFee(
        saplingInputs: 1,
        saplingOutputs: 0,
        transparentOutputs: 1,
      );
      final dustRemainder = PivxFeePolicy.shieldedDustThreshold;
      final plan = SaplingTransactionBuilder.planShieldedSpend(
        totalInput: 2000000 + noChangeFee + dustRemainder,
        amount: 2000000,
        saplingInputs: 1,
        transparentDestination: true,
      );

      expect(plan.canBuild, isTrue);
      expect(plan.change, 0);
      expect(plan.fee, noChangeFee + dustRemainder);
    });
  });
}
