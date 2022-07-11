import 'package:cake_wallet/entities/cake_phone_entities/phone_number_service.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/cake_phone_settings_tile.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/plan_card.dart';
import 'package:cake_wallet/view_model/cake_phone/phone_plan_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class AutoRenewSettingsPage extends BasePage {
  AutoRenewSettingsPage({@required this.phoneNumberService, @required this.phonePlanViewModel});

  final PhoneNumberService phoneNumberService;
  final PhonePlanViewModel phonePlanViewModel;

  @override
  Widget body(BuildContext context) => AutoRenewSettingsBody(phoneNumberService, phonePlanViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).auto_renew_settings,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.decorationColor),
    );
  }
}

class AutoRenewSettingsBody extends StatefulWidget {
  AutoRenewSettingsBody(this.phoneNumberService, this.phonePlanViewModel);

  final PhoneNumberService phoneNumberService;
  final PhonePlanViewModel phonePlanViewModel;

  @override
  AutoRenewSettingsBodyState createState() => AutoRenewSettingsBodyState();
}

class AutoRenewSettingsBodyState extends State<AutoRenewSettingsBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.symmetric(vertical: 20),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "${S.of(context).auto_renew} ${S.of(context).term}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryTextTheme.title.decorationColor,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 8),
              child: Text(
                S.of(context).auto_renew_term_description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).accentTextTheme.subhead.color,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Observer(builder: (_) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: widget.phonePlanViewModel.servicePlans
                        .map((e) => PlanCard(
                              plan: e,
                              onTap: () {
                                if (widget.phonePlanViewModel.selectedPlan != e) {
                                  widget.phonePlanViewModel.selectedPlan = e;
                                }
                              },
                              isSelected: widget.phonePlanViewModel.selectedPlan == e,
                            ))
                        .toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CakePhoneSettingsTile(
                    title: S.of(context).free_sms_email_forward,
                    value: Observer(builder: (_) {
                      return Text(
                        "${widget.phonePlanViewModel.selectedPlan.quantity}, " +
                            "${S.of(context).then} " +
                            "\$${(widget.phonePlanViewModel.rateInCents / 100).toStringAsFixed(2)} " +
                            "${S.of(context).per_message}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                      );
                    }),
                  ),
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
                ],
              ),
            ),
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            PrimaryButton(
              onPressed: () {
              },
              text: "${S.of(context).disable} ${S.of(context).auto_renew}",
              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
              textColor: Theme.of(context).primaryTextTheme.title.color,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {
              },
              text: "${S.of(context).update} ${S.of(context).auto_renew}",
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
