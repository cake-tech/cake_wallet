import 'package:flutter/material.dart';
import 'package:cake_wallet/utils/date_formatter.dart';

class DateSectionRaw extends StatelessWidget {
  DateSectionRaw({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final title = DateFormatter.convertDateTimeToReadableString(date);

    return Container(
      height: 35,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
