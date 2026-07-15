import 'dart:math';

int effectiveValue(int value, int inputCost) => value - inputCost;

class SelectedCoins {
  final List<int> indices;
  final bool hasChange;
  const SelectedCoins(this.indices, this.hasChange);
}

SelectedCoins? branchAndBound(List<int> effValues, int target, int costOfChange,
    {int maxTries = 100000}) {
  final n = effValues.length;
  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => effValues[b].compareTo(effValues[a]));
  final sorted = [for (final i in order) effValues[i]];
  final suffix = List<int>.filled(n + 1, 0);
  for (var i = n - 1; i >= 0; i--) suffix[i] = suffix[i + 1] + sorted[i];
  final upper = target + costOfChange;
  List<int>? best;
  final picked = <int>[];
  var tries = 0;
  void dfs(int i, int sum) {
    if (best != null || tries++ >= maxTries) return;
    if (sum > upper) return;
    if (sum >= target) { best = List.of(picked); return; }
    if (i >= n || sum + suffix[i] < target) return;
    picked.add(order[i]); dfs(i + 1, sum + sorted[i]); picked.removeLast();
    dfs(i + 1, sum);
  }
  dfs(0, 0);
  return best == null ? null : SelectedCoins(best!, false);
}

SelectedCoins? singleRandomDraw(List<int> effValues, int target, int minChange, Random rng) {
  final order = List<int>.generate(effValues.length, (i) => i)..shuffle(rng);
  final picked = <int>[]; var sum = 0;
  for (final i in order) {
    picked.add(i); sum += effValues[i];
    if (sum >= target + minChange) return SelectedCoins(picked, true);
  }
  return null;
}

/// Branch-and-bound over effective values (value minus the cost of spending the
/// input at the current fee rate). A match means the excess over [target] stays
/// within [window], so the remainder can be absorbed into the fee instead of
/// creating a change output. Returns null when no such subset exists.
SelectedCoins? changelessMatch({
  required List<int> values,
  required int target,
  required int inputCost,
  required int window,
  int maxTries = 100000,
}) {
  final keep = <int>[];
  final eff = <int>[];
  for (var i = 0; i < values.length; i++) {
    final e = effectiveValue(values[i], inputCost);
    if (e > 0) {
      keep.add(i);
      eff.add(e);
    }
  }
  final match = branchAndBound(eff, target, window, maxTries: maxTries);
  if (match == null) return null;
  return SelectedCoins([for (final i in match.indices) keep[i]], false);
}

class InsufficientFundsException implements Exception { const InsufficientFundsException(); }

SelectedCoins selectCoins({required List<int> values, required int target,
    required int inputCost, required int costOfChange, required int minChange, Random? rng}) {
  final keep = <int>[]; final eff = <int>[];
  for (var i = 0; i < values.length; i++) {
    final e = effectiveValue(values[i], inputCost);
    if (e > 0) { keep.add(i); eff.add(e); }
  }
  SelectedCoins? map(SelectedCoins? s) =>
      s == null ? null : SelectedCoins([for (final i in s.indices) keep[i]], s.hasChange);
  final bnb = map(branchAndBound(eff, target, costOfChange));
  if (bnb != null) return bnb;
  final srd = map(singleRandomDraw(eff, target, minChange, rng ?? Random.secure()));
  if (srd != null) return srd;
  throw const InsufficientFundsException();
}
