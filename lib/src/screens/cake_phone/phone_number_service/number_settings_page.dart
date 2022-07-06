import 'package:cake_wallet/entities/cake_phone_entities/service_plan.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/cake_phone_settings_tile.dart';
import 'package:cake_wallet/view_model/cake_phone/phone_plan_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standart_switch.dart';
import 'package:cake_wallet/entities/cake_phone_entities/phone_number_service.dart';

class NumberSettingsPage extends BasePage {
  NumberSettingsPage({@required this.phoneNumberService, @required this.phonePlanViewModel});

  final PhoneNumberService phoneNumberService;
  final PhonePlanViewModel phonePlanViewModel;

  @override
  Widget body(BuildContext context) => NumberSettingsBody(phoneNumberService, phonePlanViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).number_settings,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: titleColor ?? Theme.of(context).primaryTextTheme.title.color),
    );
  }
}

class NumberSettingsBody extends StatefulWidget {
  NumberSettingsBody(this.phoneNumberService, this.phonePlanViewModel);

  final PhoneNumberService phoneNumberService;
  final PhonePlanViewModel phonePlanViewModel;

  @override
  NumberSettingsBodyState createState() => NumberSettingsBodyState();
}

class NumberSettingsBodyState extends State<NumberSettingsBody> {
  ServicePlan selectedPhoneNumberPlan;
  bool blockIncomingSMS = true;

  @override
  void initState() {
    super.initState();

    try {
      selectedPhoneNumberPlan = widget.phonePlanViewModel.servicePlans
          .firstWhere((element) => element.id == widget.phoneNumberService.planId);
    } catch (err) {
      // the current phone plan is no longer available so check for nullability
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CakePhoneSettingsTile(
              title: S.of(context).phone_number,
              value: Text(
                widget.phoneNumberService.phoneNumber,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
            ),
            CakePhoneSettingsTile(
              title: S.of(context).auto_renew_settings,
              value: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${S.of(context).renews_every} ${selectedPhoneNumberPlan?.duration ?? 0} ${S.of(context).month} " +
                          "${S.of(context).for_amount} \$${selectedPhoneNumberPlan?.price ?? 0}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).primaryTextTheme.title.color,
                    size: 16,
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.autoRenewSettings, arguments: widget.phoneNumberService);
              },
            ),
            CakePhoneSettingsTile(
              title: S.of(context).manually_add_balance,
              value: InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${widget.phoneNumberService.usedUntil.difference(DateTime.now()).inDays} ${S.of(context).days_of_service_remaining}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).primaryTextTheme.title.color,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            CakePhoneSettingsTile(
              value: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).block_incoming_sms,
                      style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                  StandartSwitch(
                    value: blockIncomingSMS,
                    onTaped: () {
                      // TODO: block and unblock incoming sms
                      blockIncomingSMS = !blockIncomingSMS;
                      // TODO: remove setState and wrap with observer after creating the view model
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
