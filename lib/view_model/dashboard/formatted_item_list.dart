import "package:cw_core/action_list_item.dart";
import "package:cake_wallet/view_model/dashboard/date_section_item.dart";
import "package:flutter/foundation.dart";

enum _DateBucket { recent, last7Days, last30Days, byMonth }

List<HistoryListItem> formattedItemsList(List<HistoryListItem> items) {
  final formattedList = <HistoryListItem>[];
  items.sort((a, b) => b.date.compareTo(a.date));

  final now = DateTime.now();
  final todayTreshold = DateTime(now.year, now.month, now.day);
  final last7daysThreshold = now.subtract(const Duration(days: 7));
  final last30daysThreshold = now.subtract(const Duration(days: 30));

  _DateBucket? lastBucket;
  DateTime? lastMonthDate;

  for (final transaction in items) {
    final date = transaction.date;

    final bucket = date.isAfter(todayTreshold)
        ? _DateBucket.recent
        : date.isAfter(last7daysThreshold)
            ? _DateBucket.last7Days
            : date.isAfter(last30daysThreshold)
                ? _DateBucket.last30Days
                : _DateBucket.byMonth;

    switch (bucket) {
      case _DateBucket.recent:
        if (lastBucket != _DateBucket.recent) {
          formattedList.add(
            TodayTransactionItem(date),
          );
        }
        break;
      case _DateBucket.last7Days:
        if (lastBucket != _DateBucket.last7Days) {
          formattedList.add(
            Last7daysTransactionItem(date),
          );
        }
        break;
      case _DateBucket.last30Days:
        if (lastBucket != _DateBucket.last30Days) {
          formattedList.add(
            Last30daysTransactionItem(date),
          );
        }
        break;
      case _DateBucket.byMonth:
        final isNewMonth = lastMonthDate == null ||
            lastMonthDate.year != date.year ||
            lastMonthDate.month != date.month;
        if (isNewMonth) {
          lastMonthDate = date;
          formattedList.add(
            DateSectionItem(date),
          );
        }
        break;
    }

    lastBucket = bucket;
    formattedList.add(transaction);
  }

  return formattedList;
}
