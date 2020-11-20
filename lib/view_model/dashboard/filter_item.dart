class FilterItem {
  FilterItem({this.value, this.caption, this.onChanged});

  bool Function() value;
  String caption;
  Function(bool) onChanged;
}