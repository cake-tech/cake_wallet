import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class CakePayWelcomePage extends BasePage {
  CakePayWelcomePage(this._authViewModel)
      : _formKey = GlobalKey<FormState>(),
        _emailController = TextEditingController() {
    _emailController.text = _authViewModel.email;
    _emailController.addListener(() => _authViewModel.email = _emailController.text);
  }

  final GlobalKey<FormState> _formKey;

  final CakePayAuthViewModel _authViewModel;

  final TextEditingController _emailController;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.welcome_to_cakepay,
      style: textMediumSemiBold(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    reaction((_) => _authViewModel.userVerificationState, (CakePayUserVerificationState state) {
      if (state is CakePayUserVerificationStateFailure) {
        _onLoginUserFailure(context, state.error);
      }
      if (state is CakePayUserVerificationStateSuccess) {
        _onLoginSuccessful(context, _authViewModel);
      }
    });
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          SizedBox(height: 90),
          Form(
            key: _formKey,
            child: BaseTextFormField(
              hintText: S.of(context).email_address,
              keyboardType: TextInputType.emailAddress,
              validator: EmailValidator(),
              controller: _emailController,
              onSubmit: (text) => _login(),
            ),
          ),
          SizedBox(height: 20),
          Text(
            S.of(context).about_cake_pay,
            style: textLarge(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          Text(S.of(context).cake_pay_account_note,
              style: textLarge(color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
      bottomSectionPadding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      bottomSection: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Observer(
                builder: (_) => LoadingPrimaryButton(
                  text: S.of(context).login,
                  onPressed: _login,
                  isLoading:
                      _authViewModel.userVerificationState is CakePayUserVerificationStateLoading,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onLoginUserFailure(BuildContext context, String error) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.login,
              alertContent: error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  Future<void> _onLoginSuccessful(BuildContext context, CakePayAuthViewModel authViewModel) async {
    final verified = await Navigator.pushNamed<bool>(context, Routes.cakePayVerifyOtpPage,
        arguments: [authViewModel.email, true]);

    if (verified == true && Navigator.of(context).canPop()) {
      Navigator.pop(context, true);
    }
  }

  void _login() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    await _authViewModel.logIn(_emailController.text);
  }
}
