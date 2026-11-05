import "package:cake_wallet/view_model/dashboard/action_list_item.dart";
import "package:cake_wallet/view_model/dashboard/date_section_item.dart";
import "package:cake_wallet/view_model/dashboard/pending_conversion_list_item.dart";
import "package:cake_wallet/view_model/dashboard/transaction_list_item.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:flutter/foundation.dart";

enum _DateBucket { recent, last7Days, last30Days, byMonth }

bool _isPending(ActionListItem item) {
  if (item is PendingConversionListItem) return true;
  if (item is TransactionListItem) {
    return item.transaction.isPending ||
        ConversionStatusUtils.fromAdditionalInfo(item.transaction.additionalInfo) ==
            ConversionStatus.pending;
  }
  return false;
}

/// Pending rows first under their own header, whatever their date, then everything else
/// newest-first under date headers.
List<ActionListItem> formattedItemsList(List<ActionListItem> allItems) {
  final formattedList = <ActionListItem>[];
  allItems.sort((a, b) => b.date.compareTo(a.date));

  final pending = allItems.where(_isPending).toList();
  if (pending.isNotEmpty) {
    formattedList.add(
      PendingTransactionItem(pending.first.date, key: const ValueKey("pending_section_item_key")),
    );
    formattedList.addAll(pending);
  }
  final items = allItems.where((item) => !_isPending(item));

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
            TodayTransactionItem(
              date,
              key: const ValueKey("today_section_item_key"),
            ),
          );
        }
        break;
      case _DateBucket.last7Days:
        if (lastBucket != _DateBucket.last7Days) {
          formattedList.add(
            Last7daysTransactionItem(
              date,
              key: const ValueKey("last_7_days_section_item_key"),
            ),
          );
        }
        break;
      case _DateBucket.last30Days:
        if (lastBucket != _DateBucket.last30Days) {
          formattedList.add(
            Last30daysTransactionItem(
              date,
              key: const ValueKey("last_30_days_section_item_key"),
            ),
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
            DateSectionItem(
              date,
              key: ValueKey("date_section_item_${date.year}_${date.month}_key"),
            ),
          );
        }
        break;
    }

    lastBucket = bucket;
    formattedList.add(transaction);
  }

  return formattedList;
}
