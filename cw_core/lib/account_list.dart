import 'package:mobx/mobx.dart';

abstract class AccountList<T> {

  ObservableList<T> get accounts;

  void update();

  List<T> getAll();

  Future<void> addAccount({required String label});

  Future<void> setLabelAccount({required int accountIndex, required String label});

  void refresh();
}
