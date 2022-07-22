import 'package:mobx/mobx.dart';

class FilterItem {
  FilterItem({this.value, this.caption, this.onChanged});

  Observable<bool> value;
  String caption;
  Function onChanged;
}