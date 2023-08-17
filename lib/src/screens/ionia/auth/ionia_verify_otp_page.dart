import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';

class IoniaVerifyIoniaOtp extends BasePage {
  IoniaVerifyIoniaOtp(this._authViewModel, this._email, this.isSignIn)
      : _codeController = TextEditingController(),
        _codeFocus = FocusNode() {
    _codeController.addListener(() {
      final otp = _codeController.text;
      _authViewModel.otp = otp;
      if (otp.length > 3) {
        _authViewModel.otpState = IoniaOtpSendEnabled();
      } else {
        _authViewModel.otpState = IoniaOtpSendDisabled();
      }
    });
  }

  final IoniaAuthViewModel _authViewModel;
  final bool isSignIn;

  final String _email;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.verification,
      style: textMediumSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  final TextEditingController _codeController;
  final FocusNode _codeFocus;

  @override
  Widget body(BuildContext context) {
    reaction((_) => _authViewModel.otpState, (IoniaOtpState state) {
      if (state is IoniaOtpFailure) {
        _onOtpFailure(context, state.error);
      }
      if (state is IoniaOtpSuccess) {
        _onOtpSuccessful(context);
      }
    });
    return KeyboardActions(
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _codeFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        height: 0,
        color: Theme.of(context).colorScheme.background,
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.all(24),
          content: Column(
            children: [
              BaseTextFormField(
                hintText: S.of(context).enter_code,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                focusNode: _codeFocus,
                controller: _codeController,
                onSubmit: (_) => _verify(),
              ),
              SizedBox(height: 14),
              Text(
                S.of(context).fill_code,
                style: TextStyle(color: Color(0xff7A93BA), fontSize: 12),
              ),
              SizedBox(height: 34),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context).didnt_get_code),
                  SizedBox(width: 20),
                  InkWell(
                    onTap: () => isSignIn
                      ? _authViewModel.signIn(_email)
                      : _authViewModel.createUser(_email),
                    child: Text(
                      S.of(context).resend_code,
                      style: textSmallSemiBold(color: Palette.blueCraiola),
                    ),
                  ),
                ],
              ),
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
                      text: S.of(context).continue_text,
                      onPressed: _verify,
                      isDisabled: _authViewModel.otpState is IoniaOtpSendDisabled,
                      isLoading: _authViewModel.otpState is IoniaOtpValidating,
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOtpFailure(BuildContext context, String error) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.verification,
              alertContent: error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  void _onOtpSuccessful(BuildContext context) =>
      Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.ioniaManageCardsPage, (route) => route.isFirst);

  void _verify() async => await _authViewModel.verifyEmail(_codeController.text);
}
