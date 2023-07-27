import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';

List<ActionListItem> formattedItemsList(List<ActionListItem> items) {
  final formattedList = <ActionListItem>[];
  DateTime? lastDate;
  items.sort((a, b) => b.date.compareTo(a.date));

  for (var i = 0; i < items.length; i++) {
    final transaction = items[i];

    if (lastDate == null) {
      lastDate = transaction.date;
      formattedList.add(DateSectionItem(transaction.date));
      formattedList.add(transaction);
      continue;
    }

    final isCurrentDay = lastDate.year == transaction.date.year &&
        lastDate.month == transaction.date.month &&
        lastDate.day == transaction.date.day;

    if (isCurrentDay) {
      formattedList.add(transaction);
      continue;
    }

    lastDate = transaction.date;
    formattedList.add(DateSectionItem(transaction.date));
    formattedList.add(transaction);
  }

  return formattedList;
}