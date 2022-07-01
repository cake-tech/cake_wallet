import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/service_plan.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class PhoneNumberProductPage extends BasePage {
  PhoneNumberProductPage();

  @override
  Widget body(BuildContext context) => PhoneNumberProductBody();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).phone_number,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.color),
    );
  }
}

class PhoneNumberProductBody extends StatefulWidget {
  PhoneNumberProductBody();

  @override
  PhoneNumberProductBodyState createState() => PhoneNumberProductBodyState();
}

class PhoneNumberProductBodyState extends State<PhoneNumberProductBody> {
  final List<ServicePlan> dummyPlans = [
    ServicePlan(id: "1", duration: 1, price: 20, quantity: 30),
    ServicePlan(id: "2", duration: 3, price: 10, quantity: 60),
    ServicePlan(id: "3", duration: 6, price: 9, quantity: 120),
    ServicePlan(id: "4", duration: 12, price: 5, quantity: 200),
  ];

  final int rateInCents = 20;

  ServicePlan selectedPlan;

  @override
  void initState() {
    super.initState();

    selectedPlan = dummyPlans.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          children: [
            Text(
              S.of(context).initial_service_term,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryTextTheme.title.color,
                fontFamily: 'Lato',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Text(
                S.of(context).phone_number_promotion_text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).accentTextTheme.subhead.color,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dummyPlans.map((e) => planCard(e)).toList(),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              S.of(context).free_sms_email_forward,
              style: TextStyle(
                color: Theme.of(context).accentTextTheme.subhead.color,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: Theme.of(context).accentTextTheme.title.backgroundColor,
              ))),
              child: Text(
                "${selectedPlan.quantity}, " +
                    "${S.of(context).then} " +
                    "\$${(rateInCents / 100).toStringAsFixed(2)} " +
                    "${S.of(context).per_message}",
                style: TextStyle(
                  color: Theme.of(context).accentTextTheme.caption.backgroundColor,
                ),
              ),
            ),
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "${S.of(context).due_today} "),
                  TextSpan(
                    text: "\$35.00 ",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).accentTextTheme.subhead.color,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () {},
              text: S.of(context).pay_with_cake_phone,
              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
              textColor: Theme.of(context).primaryTextTheme.title.color,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {},
              text: S.of(context).pay_with_xmr,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget planCard(ServicePlan e) {
    return GestureDetector(
      onTap: () {
        if (e != selectedPlan) {
          selectedPlan = e;
          setState(() {});
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          gradient: selectedPlan == e
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selectedPlan == e ? null : Theme.of(context).primaryTextTheme.display3.decorationColor,
        ),
        child: Column(
          children: [
            Text(
              "\$${e.price}/${S.of(context).month}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selectedPlan == e ? Colors.white : Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
            Text(
              "${e.duration} ${S.of(context).month}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selectedPlan == e ? Colors.white : Theme.of(context).accentTextTheme.subhead.color,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
