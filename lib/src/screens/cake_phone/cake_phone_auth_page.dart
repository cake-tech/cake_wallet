import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class CakePhoneAuthPage extends BasePage {
  CakePhoneAuthPage({@required this.isLogin});

  final bool isLogin;

  @override
  Widget body(BuildContext context) => CakePhoneAuthBody(isLogin);

  @override
  Widget middle(BuildContext context) {
    return Text(
      isLogin ? S.of(context).login : S.of(context).signup,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.decorationColor),
    );
  }
}

class CakePhoneAuthBody extends StatefulWidget {
  CakePhoneAuthBody(this.isLogin);

  final bool isLogin;

  @override
  CakePhoneAuthBodyState createState() => CakePhoneAuthBodyState();
}

class CakePhoneAuthBodyState extends State<CakePhoneAuthBody> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.fromLTRB(24, 100, 24, 20),
        content: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
          child: BaseTextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            maxLines: 1,
            hintText: S.of(context).email_address,
            validator: (String text) {
              text = text.trim();
              if (text.isNotEmpty && RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(text)) {
                return null;
              }

              return S.of(context).invalid_email;
            },
          ),
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            PrimaryButton(
              onPressed: () {
                if (widget.isLogin) {
                  _loginCakePhone();
                } else {
                  _registerCakePhone();
                }
              },
              text: widget.isLogin ? S.of(context).login : S.of(context).create_account,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 16),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.isLogin
                          ? S.of(context).cake_phone_terms_conditions_first_section_login
                          : S.of(context).cake_phone_terms_conditions_first_section_signup,
                    ),
                    TextSpan(
                      text: " ${S.of(context).settings_terms_and_conditions}",
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.display1.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: " ${S.of(context).and} ",
                    ),
                    TextSpan(
                      text: "${S.of(context).privacy_policy} ",
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.display1.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: S.of(context).cake_phone_terms_conditions_second_section,
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).accentTextTheme.subhead.color,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _registerCakePhone() {
    // TODO: Add Registration logic
    if (_formKey.currentState.validate()) {
      Navigator.pushNamed(context, Routes.cakePhoneVerification);
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }

  void _loginCakePhone() {
    // TODO: Add Login logic
    if (_formKey.currentState.validate()) {
      Navigator.pushNamed(context, Routes.cakePhoneVerification);
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }
}
