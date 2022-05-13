import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class CreateAccountPage extends BasePage {
  CreateAccountPage() : _formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _formKey;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.sign_up,
      style: TextStyle(
        fontSize: 22,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w900,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BaseTextFormField(
              hintText: 'Email Address *',
            ),
            SizedBox(height: 20),
            BaseTextFormField(
              hintText: 'Password *',
            ),
          ],
        ),
      ),
      bottomSectionPadding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      bottomSection: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              PrimaryButton(
                text: S.of(context).create_account,
                onPressed: () {},
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'By creating account you agree to the ',
                  style: TextStyle(
                    color: Color(0xff7A93BA),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                  children: [
                    TextSpan(
                      text: S.of(context).settings_terms_and_conditions,
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.body2.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: S.of(context).privacy_policy,
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.body2.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' by CakePay'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
