import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';

class DateSectionItem extends ActionListItem {
  DateSectionItem(this.date, {required super.key});

  @override
  final DateTime date;
}

abstract class SpecificDateSectionItem extends DateSectionItem {
  SpecificDateSectionItem(super.date, {required super.key});

  String get text;
}

class Last30daysTransactionItem extends SpecificDateSectionItem {
  Last30daysTransactionItem(super.date, {required super.key});

  @override
  String get text => S.current.last_30_days;
}

class Last7daysTransactionItem extends SpecificDateSectionItem {
  Last7daysTransactionItem(super.date, {required super.key});

  @override
  String get text => S.current.last_7_days;
}

class TodayTransactionItem extends SpecificDateSectionItem {
  TodayTransactionItem(super.date, {required super.key});

  @override
  String get text => S.current.today;
}
