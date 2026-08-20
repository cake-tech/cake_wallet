import 'dart:math';
import "package:cw_bitcoin/coin_selection.dart";
import "package:flutter_test/flutter_test.dart";
void main() {
  test('effectiveValue', () {
    expect(effectiveValue(10000, 136), 9864);
    expect(effectiveValue(100, 136), -36);
  });
  test('BnB finds changeless match in window', () {
    final r = branchAndBound([200,100,90,80], 300, 50);
    expect(r, isNotNull); expect(r!.hasChange, isFalse);
    final vals=[200,100,90,80]; final sum=r.indices.map((i)=>vals[i]).reduce((a,b)=>a+b);
    expect(sum>=300 && sum<=350, isTrue);
  });
  test('BnB null when no subset in window', () {
    expect(branchAndBound([1000,900], 300, 5), isNull);
  });
  test('SRD with change', () {
    final r = singleRandomDraw([500,500,500,500], 700, 50, Random(1));
    expect(r, isNotNull); expect(r!.hasChange, isTrue);
  });
  test('SRD randomizes across seeds', () {
    final a = (singleRandomDraw([100,101,102,103,104,105],150,10,Random(1))!.indices..sort());
    final b = (singleRandomDraw([100,101,102,103,104,105],150,10,Random(9))!.indices..sort());
    expect(a, isNot(equals(b)));
  });
  test('SRD null on insufficient funds', () {
    expect(singleRandomDraw([100,100], 500, 10, Random(1)), isNull);
  });
  test('selectCoins prefers changeless BnB, else SRD', () {
    expect(selectCoins(values:[200,100,90],target:300,inputCost:0,costOfChange:20,minChange:10).hasChange, isFalse);
    expect(selectCoins(values:[500,500,500],target:700,inputCost:0,costOfChange:5,minChange:10,rng:Random(1)).hasChange, isTrue);
  });
  test('selectCoins drops non-positive effective values', () {
    // coin of value 50 with inputCost 136 -> effective -86 -> dropped; only the 1000 usable
    final r = selectCoins(values:[50,1000],target:500,inputCost:136,costOfChange:5,minChange:10,rng:Random(1));
    expect(r.indices, equals([1]));
  });
  test('changelessMatch finds a set whose effective sum lands in the window', () {
    // inputCost 100: values [50, 400, 300, 200] -> eff [dropped, 300, 200, 100]
    // target 500, window 46: eff {300, 200} = 500, exact
    final r = changelessMatch(
        values: [50, 400, 300, 200], target: 500, inputCosts: [100, 100, 100, 100], window: 46);
    expect(r, isNotNull);
    expect(r!.hasChange, isFalse);
    final effSum = r.indices.map((i) => [50, 400, 300, 200][i] - 100).reduce((a, b) => a + b);
    expect(effSum >= 500 && effSum <= 546, isTrue);
    expect(r.indices.contains(0), isFalse); // negative-eff coin never selected
  });
  test('changelessMatch returns null when no subset lands in the window', () {
    expect(
        changelessMatch(values: [10000, 9000], target: 500, inputCosts: [100, 100], window: 46),
        isNull);
  });
  test('selectCoins throws when insufficient', () {
    expect(() => selectCoins(values:[100,100],target:500,inputCost:0,costOfChange:5,minChange:10),
        throwsA(isA<InsufficientFundsException>()));
  });
  test('changeless pipeline: leftover absorbed into fee is non-negative and below dust', () {
    // Mirrors the _createUTXOS / estimateTxForAmount arithmetic with the wallet's
    // 68*inputs + 34*outputs + 10 vBytes model, at 10 sat/vB with 1 recipient output.
    const feeRate = 10;
    const amount = 50000;
    final values = [60700, 30000, 21800, 9000, 5000];
    const target = amount + (34 * 1 + 10) * feeRate;
    final r = changelessMatch(
        values: values,
        target: target,
        inputCosts: List.filled(values.length, 68 * feeRate),
        window: 546);
    expect(r, isNotNull);
    final inAmount = r!.indices.map((i) => values[i]).reduce((a, b) => a + b);
    final feeNoChange = (68 * r.indices.length + 34 * 1 + 10) * feeRate;
    final leftover = inAmount - amount - feeNoChange;
    expect(leftover >= 0, isTrue); // the caller never recurses for more inputs
    expect(leftover <= 546, isTrue); // fee overpay is bounded by the dust limit
  });
  test('BnB terminates and returns null on large pools with no possible match', () {
    // 300 even effective values, odd target, zero window: no subset can ever match,
    // so the search must stop at maxTries instead of exploring 2^300 branches.
    final values = List<int>.generate(300, (i) => 1000000 + i * 2);
    final r = changelessMatch(
        values: values, target: 1500001, inputCosts: List.filled(300, 10), window: 0);
    expect(r, isNull);
  });
  test('changelessMatch charges each input its own script-type cost', () {
    // Legacy input (148 vB) vs segwit input (68 vB) at 10 sat/vB: same value, but
    // the legacy coin's effective value is 800 lower. Target only reachable when
    // the cheaper segwit coin is chosen: eff segwit = 10000-680 = 9320.
    const feeRate = 10;
    final r = changelessMatch(
      values: [10000, 10000],
      target: 9320,
      inputCosts: [148 * feeRate, 68 * feeRate],
      window: 0,
    );
    expect(r, isNotNull);
    expect(r!.indices, equals([1]));
  });
}
