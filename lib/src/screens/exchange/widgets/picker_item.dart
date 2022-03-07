class PickerItem<T> {
  PickerItem(this.original,
      {this.title, this.iconPath, this.tag, this.description});

  final String title;
  final String iconPath;
  final String tag;
  final T original;
  final String description;
}
