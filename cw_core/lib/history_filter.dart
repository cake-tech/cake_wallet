
class HistoryFilter {
  const HistoryFilter({
    required this.key,
    required this.caption,
    required this.value,
    this.children = const [],
    this.iconPath,
  });

  final String key;

  final String caption;

  final bool value;

  final String? iconPath;

  final List<HistoryFilter> children;

  bool get hasChildren => children.isNotEmpty;

  int get enabledChildren => children.where((child) => child.value).length;

  Iterable<HistoryFilter> get descendants =>
      [this, for (final child in children) ...child.descendants];

  @override
  bool operator ==(Object other) => other is HistoryFilter && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => "HistoryFilter($key: $value)";
}
