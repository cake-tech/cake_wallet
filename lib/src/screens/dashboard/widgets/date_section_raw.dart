import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
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
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).extension<CakeTextTheme>()!.dateSectionRowColor,
        ),
      ),
    );
  }
}
