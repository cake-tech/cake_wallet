import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_tile.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';
import 'package:cake_wallet/src/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
//import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;

class FilterWidget extends StatelessWidget {
  FilterWidget({required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;
  final closeIcon =
  Image.asset('assets/images/close.png', color: Palette.darkBlueCraiola);

  @override
  Widget build(BuildContext context) {
    const sectionDivider = SectionDivider();
    return AlertBackground(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: Container(
                    color: Theme.of(context)
                        .textTheme!
                        .bodyText1!
                        .decorationColor!,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              S.of(context).filters,
                              style: TextStyle(
                                color: Theme.of(context).primaryTextTheme
                                    .overline!.color!,
                                fontSize: 16,
                                fontFamily: 'Lato',
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          sectionDivider,
                          ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dashboardViewModel.filterItems.length,
                            separatorBuilder: (context, _) => sectionDivider,
                            itemBuilder: (_, index1) {
                              final title = dashboardViewModel.filterItems.keys
                                  .elementAt(index1);
                              final section = dashboardViewModel
                                  .filterItems.values
                                  .elementAt(index1);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 20, left: 24, right: 24),
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .primaryTextTheme!
                                              .headline6!
                                              .color!,
                                          fontSize: 16,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none),
                                    ),
                                  ),
                                  ListView.builder(
                                    padding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: section.length,
                                    itemBuilder: (_, index2) {
                                      final item = section[index2];
                                      final content = item.onChanged != null
                                          ? Observer(
                                          builder: (_) =>
                                              RoundedCheckboxWidget(
                                                value: item.value.value,
                                                caption: item.caption,
                                                onChanged: item.onChanged,
                                                currentTheme:
                                                dashboardViewModel
                                                    .settingsStore
                                                    .currentTheme,
                                              ))
                                          : GestureDetector(
                                        onTap: () async {
                                          //final List<DateTime> picked =
                                          //await date_rage_picker.showDatePicker(
                                          //    context: context,
                                          //    initialFirstDate: DateTime.now()
                                          //        .subtract(Duration(days: 1)),
                                          //    initialLastDate: (DateTime.now()),
                                          //    firstDate: DateTime(2015),
                                          //    lastDate: DateTime.now()
                                          //        .add(Duration(days: 1)));

                                          //if (picked != null && picked.length == 2) {
                                          //  dashboardViewModel.transactionFilterStore
                                          //      .changeStartDate(picked.first);
                                          //  dashboardViewModel.transactionFilterStore
                                          //      .changeEndDate(picked.last);
                                          //}
                                        },
                                        child: Padding(
                                          padding:
                                          EdgeInsets.only(left: 32),
                                          child: Text(
                                            item.caption,
                                            style: TextStyle(
                                                color: Colors.red,
                                                //Theme.of(context).primaryTextTheme.title.color,//
                                                fontSize: 18,
                                                fontFamily: 'Lato',
                                                fontWeight:
                                                FontWeight.w500,
                                                decoration:
                                                TextDecoration.none),
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
                        ]),
                  ),
                ),
              ),
            ],
          ),
          AlertCloseButton(image: closeIcon)
        ],
      ),
    );
  }
}

class SectionDivider extends StatelessWidget {
  const SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}