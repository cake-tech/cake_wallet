import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:date_range_picker/date_range_picker.dart' as date_rage_picker;
import 'package:flutter_mobx/flutter_mobx.dart';

class HeaderRow extends StatelessWidget {
  HeaderRow({this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final filterIcon = Image.asset('assets/images/filter_icon.png',
        color: Theme.of(context).textTheme.caption.decorationColor);

    return Container(
      height: 52,
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            S.of(context).transactions,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white
            ),
          ),
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              PopupMenuItem(
                  enabled: false,
                  value: -1,
                  child: Text(S.of(context).transactions,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryTextTheme.title.color))),
              PopupMenuItem(
                  value: 0,
                  child: Observer(
                      builder: (_) => Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text(S.of(context).incoming,
                              style: TextStyle(
                                color: Theme.of(context).primaryTextTheme.title.color
                              ),
                            ),
                            Checkbox(
                                value: dashboardViewModel
                                    .transactionFilterStore
                                    .displayIncoming,
                                onChanged: (value) => dashboardViewModel
                                    .transactionFilterStore
                                    .toggleIncoming()
                            )
                          ]))),
              PopupMenuItem(
                  value: 1,
                  child: Observer(
                      builder: (_) => Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text(S.of(context).outgoing,
                                style: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.title.color
                                )
                            ),
                            Checkbox(
                              value: dashboardViewModel
                                  .transactionFilterStore
                                  .displayOutgoing,
                              onChanged: (value) => dashboardViewModel
                                  .transactionFilterStore
                                  .toggleOutgoing(),
                            )
                          ]))),
              PopupMenuItem(
                  value: 2,
                  child:
                  Text(S.of(context).transactions_by_date,
                      style: TextStyle(
                          color: Theme.of(context).primaryTextTheme.title.color
                      )
                  )),
              PopupMenuDivider(),
              PopupMenuItem(
                  enabled: false,
                  value: -1,
                  child: Text(S.of(context).trades,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryTextTheme.title.color))),
              PopupMenuItem(
                  value: 3,
                  child: Observer(
                      builder: (_) => Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text('XMR.TO',
                                style: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.title.color
                                )
                            ),
                            Checkbox(
                              value: dashboardViewModel
                                  .tradeFilterStore
                                  .displayXMRTO,
                              onChanged: (value) => dashboardViewModel
                                  .tradeFilterStore
                                  .toggleDisplayExchange(
                                  ExchangeProviderDescription
                                      .xmrto),
                            )
                          ]))),
              PopupMenuItem(
                  value: 4,
                  child: Observer(
                      builder: (_) => Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text('Change.NOW',
                                style: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.title.color
                                )
                            ),
                            Checkbox(
                              value: dashboardViewModel
                                  .tradeFilterStore
                                  .displayChangeNow,
                              onChanged: (value) => dashboardViewModel
                                  .tradeFilterStore
                                  .toggleDisplayExchange(
                                  ExchangeProviderDescription
                                      .changeNow),
                            )
                          ]))),
              PopupMenuItem(
                  value: 5,
                  child: Observer(
                      builder: (_) => Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text('MorphToken',
                                style: TextStyle(
                                    color: Theme.of(context).primaryTextTheme.title.color
                                )
                            ),
                            Checkbox(
                              value: dashboardViewModel
                                  .tradeFilterStore
                                  .displayMorphToken,
                              onChanged: (value) => dashboardViewModel
                                  .tradeFilterStore
                                  .toggleDisplayExchange(
                                  ExchangeProviderDescription
                                      .morphToken),
                            )
                          ])))
            ],
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).textTheme.overline.color
              ),
              child: filterIcon,
            ),
            onSelected: (item) async {
              if (item == 2) {
                final picked =
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
              }
            },
          ),
        ],
      ),
    );
  }
}