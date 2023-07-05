import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_auth_view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class IoniaCreateAccountPage extends BasePage {
  IoniaCreateAccountPage(this._authViewModel)
      : _emailFocus = FocusNode(),
        _emailController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _emailController.text = _authViewModel.email;
    _emailController.addListener(() => _authViewModel.email = _emailController.text);
  }

  final IoniaAuthViewModel _authViewModel;

  final GlobalKey<FormState> _formKey;

  final FocusNode _emailFocus;
  final TextEditingController _emailController;

  static const privacyPolicyUrl = 'https://ionia.docsend.com/view/jhjvdn7qq7k3ukwt';
  static const termsAndConditionsUrl = 'https://ionia.docsend.com/view/uceirymz2ijacq5g';

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.sign_up,
      style: textMediumSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    reaction((_) => _authViewModel.createUserState, (IoniaCreateAccountState state) {
      if (state is IoniaCreateStateFailure) {
        _onCreateUserFailure(context, state.error);
      }
      if (state is IoniaCreateStateSuccess) {
        _onCreateSuccessful(context, _authViewModel);
      }
    });

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Form(
        key: _formKey,
        child: BaseTextFormField(
          hintText: S.of(context).email_address,
          focusNode: _emailFocus,
          validator: EmailValidator(),
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
          onSubmit: (_) => _createAccount(),
        ),
      ),
      bottomSectionPadding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      bottomSection: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  text: S.of(context).create_account,
                  onPressed: _createAccount,
                  isLoading:
                      _authViewModel.createUserState is IoniaCreateStateLoading,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: S.of(context).agree_to,
                  style: TextStyle(
                    color: Color(0xff7A93BA),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                  children: [
                    TextSpan(
                      text: S.of(context).settings_terms_and_conditions,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (await canLaunch(termsAndConditionsUrl)) await launch(termsAndConditionsUrl);
                        },
                    ),
                    TextSpan(text: ' ${S.of(context).and} '),
                    TextSpan(
                        text: S.of(context).privacy_policy,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            if (await canLaunch(privacyPolicyUrl)) await launch(privacyPolicyUrl);
                          }),
                    TextSpan(text: ' ${S.of(context).by_cake_pay}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onCreateUserFailure(BuildContext context, String error) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.create_account,
              alertContent: error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  void _onCreateSuccessful(BuildContext context, IoniaAuthViewModel authViewModel) => Navigator.pushNamed(
        context,
        Routes.ioniaVerifyIoniaOtpPage,
        arguments: [authViewModel.email, false],
      );

  void _createAccount() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    await _authViewModel.createUser(_emailController.text);
  }
}
