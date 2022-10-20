import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/add_options_tile.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/info_text_column.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/subscribed_phone_numbers.dart';

class ActiveServicesPage extends BasePage {
  ActiveServicesPage();

  @override
  Widget body(BuildContext context) => ActiveServicesBody();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).active_services,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: titleColor ?? Theme.of(context).primaryTextTheme.titleMedium?.color),
    );
  }
}

class ActiveServicesBody extends StatefulWidget {
  ActiveServicesBody();

  @override
  ActiveServicesBodyState createState() => ActiveServicesBodyState();
}

class ActiveServicesBodyState extends State<ActiveServicesBody> {
  // TODO: remove const dummy variables
  final int freeSMSCount = 50;
  final int freeMBCount = 0;
  final int serviceDaysLeft = 23;
  final double accountBalance = 20.34;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, Routes.cakePhoneProducts);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryTextTheme.subtitle1!.color!,
                      Theme.of(context)
                          .primaryTextTheme
                          .subtitle1!
                          .decorationColor!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(S.of(context).new_phone_number,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
            const SizedBox(height: 8),
            freeBalanceInfoRow(),
            const SizedBox(height: 24),
            AddOptionsTile(
              leading: InfoTextColumn(
                title: S.of(context).account_balance,
                subtitle: "\$${accountBalance.toStringAsFixed(2)}",
                isReversed: true,
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.addBalance);
              },
            ),
            const SizedBox(height: 64),
            SubscribedPhoneNumbers(),
          ],
        ),
      ),
    );
  }

  Widget freeBalanceInfoRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: Theme.of(context).primaryTextTheme.displayMedium?.decorationColor,
            ),
            child: InfoTextColumn(
              title: S.of(context).free_sms_balance,
              subtitle: "${freeSMSCount} SMS",
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              isReversed: true,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: Theme.of(context).primaryTextTheme.displayMedium?.decorationColor,
            ),
            child: InfoTextColumn(
              title: S.of(context).free_data_balance,
              subtitle: "${freeMBCount} MB",
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              isReversed: true,
            ),
          ),
        ),
      ],
    );
  }
}
