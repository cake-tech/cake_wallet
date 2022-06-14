import 'package:cake_wallet/core/email_validator.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class IoniaLoginPage extends BasePage {
  IoniaLoginPage(this._ioniaViewModel)
      : _formKey = GlobalKey<FormState>(),
        _emailController = TextEditingController() {
    _emailController.text = _ioniaViewModel.email;
    _emailController.addListener(() => _ioniaViewModel.email = _emailController.text);
  }

  final GlobalKey<FormState> _formKey;

  final IoniaViewModel _ioniaViewModel;

  @override
  Color get titleColor => Colors.black;

  final TextEditingController _emailController;

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
    reaction((_) => _ioniaViewModel.createUserState, (IoniaCreateAccountState state) {
      if (state is IoniaCreateStateFailure) {
        _onLoginUserFailure(context, state.error);
      }
      if (state is IoniaCreateStateSuccess) {
        _onLoginSuccessful(context, _ioniaViewModel);
      }
    });
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Form(
        key: _formKey,
        child: BaseTextFormField(
          hintText: S.of(context).email_address,
          validator: EmailValidator(),
          controller: _emailController,
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
                  text: S.of(context).login,
                  onPressed: () async {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    await _ioniaViewModel.createUser(_emailController.text);
                  },
                  isLoading: _ioniaViewModel.createUserState is IoniaCreateStateLoading,
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
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

  void _onLoginSuccessful(BuildContext context, IoniaViewModel ioniaViewModel) => Navigator.pushNamed(
        context,
        Routes.ioniaVerifyIoniaOtpPage,
        arguments: [ioniaViewModel.email, ioniaViewModel],
      );
}
