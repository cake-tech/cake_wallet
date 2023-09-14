import 'package:mobx/mobx.dart';

part 'check_box_picker_store.g.dart';

class CheckBoxItem = _CheckBoxItem with _$CheckBoxItem;

abstract class _CheckBoxItem with Store {
  _CheckBoxItem(this.title, this.value, {this.isDisabled = false});

  final String title;
  final bool isDisabled;

  @observable
  bool value;
}