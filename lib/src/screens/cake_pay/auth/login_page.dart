import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class LoginPage extends BasePage {
  LoginPage() : _formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _formKey;
  @override
  Color get titleColor => Colors.black;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.login,
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
              hintText: 'Email Address',
            ),
            SizedBox(height: 20),
            BaseTextFormField(
              hintText: 'Password',
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
                text: S.of(context).login,
                onPressed: () {},
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () => Navigator.of(context).pushNamed(Routes.cakePayForgotPasswordPage),
                child: Text(
                  S.of(context).forgot_password,
                  style: TextStyle(
                    color: Palette.blueCraiola,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
