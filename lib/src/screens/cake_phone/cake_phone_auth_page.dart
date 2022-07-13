import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/view_model/cake_phone/cake_phone_auth_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';

class CakePhoneAuthPage extends BasePage {
  CakePhoneAuthPage({@required this.isLogin, @required this.cakePhoneAuthViewModel});

  final bool isLogin;
  final CakePhoneAuthViewModel cakePhoneAuthViewModel;

  @override
  Widget body(BuildContext context) => CakePhoneAuthBody(isLogin, cakePhoneAuthViewModel);

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
  CakePhoneAuthBody(this.isLogin, this.cakePhoneAuthViewModel);

  final bool isLogin;
  final CakePhoneAuthViewModel cakePhoneAuthViewModel;

  @override
  CakePhoneAuthBodyState createState() => CakePhoneAuthBodyState();
}

class CakePhoneAuthBodyState extends State<CakePhoneAuthBody> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  ReactionDisposer _reaction;
  Flushbar<void> _authBar;

  @override
  void initState() {
    super.initState();

    _reaction ??= reaction((_) => widget.cakePhoneAuthViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        _authBar?.dismiss();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, Routes.cakePhoneVerification);
        });
      }

      if (state is IsExecutingState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authBar = createBar<void>(S.of(context).authentication, duration: null)..show(context);
        });
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authBar?.dismiss();
          showBar<void>(context, S.of(context).failed_authentication(state.error));
        });
      }
    });
  }

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
                if (_formKey.currentState.validate()) {
                  widget.cakePhoneAuthViewModel.auth(_emailController.text);
                } else {
                  setState(() {
                    _autoValidate = AutovalidateMode.always;
                  });
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
                        color: Palette.blueCraiola,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: " ${S.of(context).and} ",
                    ),
                    TextSpan(
                      text: "${S.of(context).privacy_policy} ",
                      style: TextStyle(
                        color: Palette.blueCraiola,
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
}
