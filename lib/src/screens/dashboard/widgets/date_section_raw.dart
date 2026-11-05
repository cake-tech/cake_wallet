import 'package:flutter/material.dart';
import 'package:cake_wallet/utils/date_formatter.dart';

class DateSectionRaw extends StatelessWidget {
  DateSectionRaw({required this.date, this.text, super.key});

  final DateTime date;

  /// Shown instead of the formatted [date] - for headers that aren't a date, e.g. "Pending".
  final String? text;

  @override
  Widget build(BuildContext context) {
    final title = text ?? DateFormatter.convertDateTimeToReadableString(date);

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
