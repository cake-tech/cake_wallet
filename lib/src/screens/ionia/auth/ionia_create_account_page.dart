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
import 'package:cake_wallet/view_model/ionia/ionia_gift_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class IoniaCreateAccountPage extends BasePage {
  IoniaCreateAccountPage(this._giftCardsListViewModel)
      : _emailFocus = FocusNode(),
        _emailController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _emailController.text = _giftCardsListViewModel.email;
    _emailController.addListener(() => _giftCardsListViewModel.email = _emailController.text);
  }

  final IoniaGiftCardsListViewModel _giftCardsListViewModel;

  final GlobalKey<FormState> _formKey;

  final FocusNode _emailFocus;
  final TextEditingController _emailController;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.sign_up,
      style: textLargeSemiBold(
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    reaction((_) => _giftCardsListViewModel.createUserState, (IoniaCreateAccountState state) {
      if (state is IoniaCreateStateFailure) {
        _onCreateUserFailure(context, state.error);
      }
      if (state is IoniaCreateStateSuccess) {
        _onCreateSuccessful(context, _giftCardsListViewModel);
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
                  onPressed: () async {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    await _giftCardsListViewModel.createUser(_emailController.text);
                  },
                  isLoading: _giftCardsListViewModel.createUserState is IoniaCreateStateLoading,
                  color: Theme.of(context).accentTextTheme.body2.color,
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
                        color: Theme.of(context).accentTextTheme.body2.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' ${S.of(context).and} '),
                    TextSpan(
                      text: S.of(context).privacy_policy,
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.body2.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

  void _onCreateSuccessful(BuildContext context, IoniaGiftCardsListViewModel giftCardsListViewModel) => Navigator.pushNamed(
        context,
        Routes.ioniaVerifyIoniaOtpPage,
        arguments: [giftCardsListViewModel.email, giftCardsListViewModel],
      );
}
