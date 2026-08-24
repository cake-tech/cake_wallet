import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/action_list_item.dart';

class DateSectionItem with ActionListItem {
  DateSectionItem(this.date);

  @override
  final DateTime date;

  @override
  String get id => date.millisecondsSinceEpoch.toString();
}

abstract class SpecificDateSectionItem extends DateSectionItem {
  SpecificDateSectionItem(super.date);

  String get text;
}

class Last30daysTransactionItem extends SpecificDateSectionItem {
  Last30daysTransactionItem(super.date);

  @override
  String get text => S.current.last_30_days;
}

class Last7daysTransactionItem extends SpecificDateSectionItem {
  Last7daysTransactionItem(super.date);

  @override
  String get text => S.current.last_7_days;
}

class TodayTransactionItem extends SpecificDateSectionItem {
  TodayTransactionItem(super.date);

  @override
  String get text => S.current.today;
}
