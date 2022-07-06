import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaAccountCardsPage extends BasePage {
  IoniaAccountCardsPage(this.ioniaAccountViewModel);

  final IoniaAccountViewModel ioniaAccountViewModel;
  
  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).cards,
      style: textLargeSemiBold(
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return _IoniaCardTabs();
  }
}

class _IoniaCardTabs extends StatefulWidget {
  @override
  _IoniaCardTabsState createState() => _IoniaCardTabsState();
}

class _IoniaCardTabsState extends State<_IoniaCardTabs> with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 45,
              width: 230,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).accentTextTheme.display4.backgroundColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  25.0,
                ),
              ),
              child: Theme(
                data: ThemeData(
                  primaryTextTheme: TextTheme(
                    body2: TextStyle(backgroundColor: Colors.transparent)
                  )
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      25.0,
                    ),
                    color: Theme.of(context).accentTextTheme.body2.color,
                  ),
                  labelColor: Theme.of(context).primaryTextTheme.display4.backgroundColor,
                  unselectedLabelColor: Theme.of(context).primaryTextTheme.title.color,
                  tabs: [
                    Tab(
                      text: S.of(context).active,
                    ),
                    Tab(
                      text: S.of(context).redeemed,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Center(
                    child: Text(
                      S.of(context).gift_card_balance_note,
                      textAlign: TextAlign.center,
                      style: textSmall(color: Theme.of(context).primaryTextTheme.overline.color,),
                    ),
                  ),

                  Center(
                    child: Text(
                      S.of(context).gift_card_redeemed_note,
                         textAlign: TextAlign.center,
                      style: textSmall(color: Theme.of(context).primaryTextTheme.overline.color,),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
