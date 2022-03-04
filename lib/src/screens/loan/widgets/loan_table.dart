import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/view_model/loan/loan_item.dart';
import 'package:flutter/material.dart';

class LoanTable extends StatelessWidget {
  LoanTable({
    @required this.loanItems,
    @required this.emptyListText,
  });
  final List<LoanItem> loanItems;
  final String emptyListText;

  Color get textColor =>
      getIt.get<SettingsStore>().currentTheme.type == ThemeType.dark
          ? Colors.white
          : Color(0xff393939);

  @override
  Widget build(BuildContext context) {
    final items = loanItems;
    if (items == null || items.isEmpty)
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            emptyListText,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      );
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ID',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ),
              SizedBox(width: 25),
            ],
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              InkWell(
                onTap: () => Navigator.of(context)
                    .pushNamed(Routes.loanDetails, arguments: items[i]),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffF1EDFF),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '5395821325',
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '10000 USDT',
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Awaiting deposit',
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right)
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
            ]
          ],
        )
      ],
    );
  }
}
