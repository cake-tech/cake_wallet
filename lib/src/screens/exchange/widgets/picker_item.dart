class PickerItem<T> {
  PickerItem(this.original,
      {required this.title,
      required this.iconPath,
      required this.tag,
      required this.description});

  final String title;
  final String iconPath;
  final String tag;
  final T original;
  final String description;
}
