import "dart:async";

class SolanaLookupBudget {
  final _spent = Completer<void>();

  void markSpent() => _spent.complete();

  // A spent budget does not start the lookup, and stops waiting for one that is still out.
  Future<T?> run<T>(Future<T?> Function() lookup, {required Duration timeout}) {
    if (_spent.isCompleted) {
      return Future.value();
    }

    return Future.any([
      lookup().timeout(timeout, onTimeout: () => null),
      _spent.future.then((_) => null),
    ]);
  }
}
