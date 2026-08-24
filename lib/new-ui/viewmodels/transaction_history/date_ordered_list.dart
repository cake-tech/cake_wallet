import "package:cw_core/action_list_item.dart";

extension InsertionPoint on List<ActionListItem> {
  int insertionPoint(DateTime date) {
    var low = 0;
    var high = length;

    while (low < high) {
      final mid = (low + high) >> 1;
      if (date.compareTo(this[mid].date) > 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return low;
  }
}
