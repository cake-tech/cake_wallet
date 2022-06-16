import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class IoniaVerifyIoniaOtp extends BasePage {
  
  IoniaVerifyIoniaOtp(this._ioniaViewModel, this._email)
      : _codeController = TextEditingController(),
        _codeFocus = FocusNode() {
    _codeController.addListener(() {
      final otp = _codeController.text;
      _ioniaViewModel.otp = otp;
      if (otp.length > 3) {
        _ioniaViewModel.otpState = IoniaOtpSendEnabled();
      } else {
        _ioniaViewModel.otpState = IoniaOtpSendDisabled();
      }
    });
  }

  final IoniaViewModel _ioniaViewModel;

  final String _email;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.verification,
      style: TextStyle(
        fontSize: 22,
        fontFamily: 'Lato',
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  final TextEditingController _codeController;
  final FocusNode _codeFocus;

  @override
  Widget body(BuildContext context) {
    reaction((_) => _ioniaViewModel.otpState, (IoniaOtpState state) {
      if (state is IoniaOtpFailure) {
        _onOtpFailure(context, state.error);
      }
      if (state is IoniaOtpSuccess) {
        _onOtpSuccessful(context);
      }
    });
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          BaseTextFormField(
            hintText: S.of(context).enter_code,
            focusNode: _codeFocus,
            controller: _codeController,
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
              Text(S.of(context).dont_get_code),
              SizedBox(width: 20),
              InkWell(
                onTap: () => _ioniaViewModel.createUser(_email),
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
                  onPressed: () async => await _ioniaViewModel.verifyEmail(_codeController.text),
                  isDisabled: _ioniaViewModel.otpState is IoniaOtpSendDisabled,
                  isLoading: _ioniaViewModel.otpState is IoniaOtpValidating,
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ],
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
      Navigator.pushNamedAndRemoveUntil(context, Routes.ioniaManageCardsPage, ModalRoute.withName(Routes.dashboard));
}
