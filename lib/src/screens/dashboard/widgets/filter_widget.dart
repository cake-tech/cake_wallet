import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_tile.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/widgets/checkbox_widget.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;

class FilterWidget extends StatelessWidget {
  FilterWidget({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;
  final backVector = Image.asset('assets/images/back_vector.png',
    color: Palette.darkBlueCraiola
  );

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                S.of(context).filters,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  decoration: TextDecoration.none,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  child: Container(
                    color: Theme.of(context).textTheme.body2.decorationColor,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashboardViewModel.filterItems.length,
                      separatorBuilder: (context, _) => Container(
                        height: 1,
                        color: Theme.of(context).accentTextTheme.subhead.backgroundColor,
                      ),
                      itemBuilder: (_, index1) {
                        final title = dashboardViewModel.filterItems.keys.elementAt(index1);
                        final section = dashboardViewModel.filterItems.values.elementAt(index1);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(
                                top: 20,
                                left: 24,
                                right: 24
                              ),
                              child: Text(
                                title,
                                style: TextStyle(
                                    color: Theme.of(context).accentTextTheme.subhead.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    decoration: TextDecoration.none
                                ),
                              ),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.length,
                              separatorBuilder: (context, _) => Container(
                                height: 1,
                                padding: EdgeInsets.only(left: 24),
                                color: Theme.of(context).textTheme.body2.decorationColor,
                                child: Container(
                                  height: 1,
                                  color: Theme.of(context).accentTextTheme.subhead.backgroundColor,
                                ),
                              ),
                              itemBuilder: (_, index2) {

                                final item = section[index2];
                                final content = item.onChanged != null
                                    ? CheckboxWidget(
                                    value: item.value(),
                                    caption: item.caption,
                                    onChanged: item.onChanged
                                )
                                    : GestureDetector(
                                  onTap: () async {
                                    final List<DateTime> picked =
                                    await date_rage_picker.showDatePicker(
                                        context: context,
                                        initialFirstDate: DateTime.now()
                                            .subtract(Duration(days: 1)),
                                        initialLastDate: (DateTime.now()),
                                        firstDate: DateTime(2015),
                                        lastDate: DateTime.now()
                                            .add(Duration(days: 1)));

                                    if (picked != null && picked.length == 2) {
                                      dashboardViewModel.transactionFilterStore
                                          .changeStartDate(picked.first);
                                      dashboardViewModel.transactionFilterStore
                                          .changeEndDate(picked.last);
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 32),
                                    child: Text(
                                      item.caption,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryTextTheme.title.color,
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.none
                                      ),
                                    ),
                                  ),
                                );

                                return FilterTile(child: content);
                              },
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          AlertCloseButton(image: backVector)
        ],
      ),
    );
  }
}