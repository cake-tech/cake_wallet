import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

class LoanDetailTile extends StatelessWidget {
  LoanDetailTile({
    @required this.title,
    this.subtitle,
    @required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  Color get textColor =>
      currentTheme.type == ThemeType.dark ? Colors.white : Color(0xff393939);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           SizedBox(
                    width: 150,
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            subtitle != null
                ? SizedBox(
                    width: 200,
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        Text(
          trailing,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
