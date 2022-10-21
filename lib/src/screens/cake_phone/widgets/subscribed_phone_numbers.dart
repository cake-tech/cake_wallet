import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/cake_phone_entities/phone_number_service.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/add_options_tile.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/info_text_column.dart';

class SubscribedPhoneNumbers extends StatefulWidget {
  const SubscribedPhoneNumbers({Key? key}) : super(key: key);

  @override
  _SubscribedPhoneNumbersState createState() => _SubscribedPhoneNumbersState();
}

class _SubscribedPhoneNumbersState extends State<SubscribedPhoneNumbers> {
  int selectedTab = 0;
  final List<PhoneNumberService> subscribedPhoneNumbers = [
    PhoneNumberService(
        id: "1", planId: "1", phoneNumber: "+1 888-888-8888", usedUntil: DateTime.now().add(Duration(days: 24))),
    PhoneNumberService(
        id: "2", planId: "2", phoneNumber: "+1 888-888-8888", usedUntil: DateTime.now().add(Duration(days: 26))),
    PhoneNumberService(
        id: "3", planId: "3", phoneNumber: "+1 999-999-9999", usedUntil: DateTime.now().subtract(Duration(days: 24))),
    PhoneNumberService(
        id: "4", planId: "4", phoneNumber: "+1 999-999-9999", usedUntil: DateTime.now().subtract(Duration(days: 26))),
  ];

  final List<PhoneNumberService> activePhoneNumbers = [];
  final List<PhoneNumberService> expiredPhoneNumbers = [];

  @override
  void initState() {
    super.initState();

    for (PhoneNumberService element in subscribedPhoneNumbers) {
      if (element.usedUntil.isAfter(DateTime.now())) {
        activePhoneNumbers.add(element);
      } else {
        expiredPhoneNumbers.add(element);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: Theme.of(context).primaryTextTheme.headline2?.decorationColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              tab(S.of(context).active, 0),
              tab(S.of(context).expired, 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...(selectedTab == 0 ? activePhoneNumbers : expiredPhoneNumbers).map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AddOptionsTile(
              leading: InfoTextColumn(
                title: e.phoneNumber,
                subtitle: selectedTab == 0
                    ? "${e.usedUntil.difference(DateTime.now()).inDays} ${S.of(context).days_of_service_remaining}"
                    : S.of(context).expired,
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.numberSettings, arguments: e);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget tab(String title, int tabIndex) {
    final selected = selectedTab == tabIndex;
    return GestureDetector(
      onTap: () {
        if (!selected) {
          setState(() {
            selectedTab = tabIndex;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: selected
              ? Theme.of(context).accentTextTheme.bodyText1?.color
              : Theme.of(context).primaryTextTheme.headline2?.decorationColor,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Theme.of(context).primaryTextTheme.headline6?.color,
          ),
        ),
      ),
    );
  }
}
