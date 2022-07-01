import 'package:mobx/mobx.dart';

abstract class AccountList<T> {

  ObservableList<T> get accounts;

  void update();

  List<T> getAll();

  Future addAccount({String? label});

  Future setLabelAccount({int? accountIndex, String? label});

  void refresh();
}
