abstract class AccountList<T> {
  List<T> get accounts;

  Future<void> update();

  Future<void> addAccount({required String label});

  Future<void> setLabelAccount({
    required int accountIndex,
    required String label,
  });
}
