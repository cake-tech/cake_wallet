import 'package:cake_wallet/generated/i18n.dart';

enum FilterListOrderType {
  CreationDate,
  Alphabetical,
  GroupByType,
  Custom;

  @override
  String toString() {
    switch (this) {
      case FilterListOrderType.CreationDate:
        return S.current.creation_date;
      case FilterListOrderType.Alphabetical:
        return S.current.alphabetical;
      case FilterListOrderType.GroupByType:
        return S.current.group_by_type;
      case FilterListOrderType.Custom:
        return S.current.custom_drag;
    }
  }
}
