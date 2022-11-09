class FilterItem {
  FilterItem({
    required this.value,
    required this.caption,
    required this.onChanged});

  bool Function() value;
  String caption;
  Function(bool) onChanged;
}