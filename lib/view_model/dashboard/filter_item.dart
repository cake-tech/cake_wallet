import 'package:mobx/mobx.dart';

class FilterItem {
  FilterItem({
    required this.value,
    required this.caption,
    required this.onChanged});

  Observable<bool> value;
  String caption;
  Function onChanged;
}