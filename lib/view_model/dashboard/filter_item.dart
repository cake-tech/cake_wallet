class FilterItem {
  FilterItem({this.value, this.caption, this.onChanged});

  bool value;
  String caption;
  Function(bool) onChanged;
}