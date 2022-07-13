import 'dart:async';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/cake_phone/cake_phone_auth_view_model.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';

class CakePhoneVerificationPage extends BasePage {
  CakePhoneVerificationPage(this.authViewModel);

  final CakePhoneAuthViewModel authViewModel;

  @override
  Widget body(BuildContext context) => CakePhoneVerificationBody(authViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).email_verification,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.decorationColor),
    );
  }
}

class CakePhoneVerificationBody extends StatefulWidget {
  CakePhoneVerificationBody(this.authViewModel);

  final CakePhoneAuthViewModel authViewModel;

  @override
  CakePhoneVerificationBodyState createState() => CakePhoneVerificationBodyState();
}

class CakePhoneVerificationBodyState extends State<CakePhoneVerificationBody> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  int resendCount = 0;
  int timeLeft = 0;

  bool disabled = true;

  ReactionDisposer _reaction;
  Flushbar<void> _authBar;

  @override
  void initState() {
    super.initState();

    _startTimer();

    _codeController.addListener(() {
      if (_codeController.text.isEmpty) {
        disabled = true;
        setState(() {});
      } else if (disabled) {
        disabled = false;
        setState(() {});
      }
    });

    _reaction ??= reaction((_) => widget.authViewModel.state, (ExecutionState state) {
      if (state is ExecutedSuccessfullyState) {
        _authBar?.dismiss();
        WidgetsBinding.instance.addPostFrameCallback((_) {
        final userExists = state.payload as bool;
          Navigator.pushNamedAndRemoveUntil(
            context,
            userExists ? Routes.cakePhoneActiveServices : Routes.cakePhoneProducts,
            ModalRoute.withName(Routes.cakePhoneWelcome),
          );
          /// reset the authentication view model
          getIt.resetLazySingleton<CakePhoneAuthViewModel>(instance: widget.authViewModel);
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
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                S.of(context).fill_verification_code,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryTextTheme.title.color,
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: BaseTextFormField(
                  controller: _codeController,
                  maxLines: 1,
                  hintText: S.of(context).verification_code,
                  suffixIcon: timeLeft > 0
                      ? null
                      : InkWell(
                          onTap: _startTimer,
                          child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).accentTextTheme.caption.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                S.of(context).get_code,
                                style: TextStyle(
                                  color: Theme.of(context).primaryTextTheme.title.color,
                                  fontWeight: FontWeight.w900,
                                ),
                              )),
                        ),
                  validator: (String text) {
                    // TODO: check and apply verification constraints with backend
                    if (text.length < 4) {
                      return S.of(context).invalid_verification_code;
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (timeLeft > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).did_not_get_code,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  Text(
                    S.of(context).resend_code_in + " ${timeLeft ~/ 60}:" + (timeLeft % 60).toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.subtitle.color,
                    ),
                  ),
                ],
              ),
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            PrimaryButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  widget.authViewModel.verify(_codeController.text);
                } else {
                  setState(() {
                    _autoValidate = AutovalidateMode.always;
                  });
                }
              },
              text: S.of(context).continue_text,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
              isDisabled: disabled,
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    resendCount++;
    timeLeft = (resendCount * 30);
    setState(() {});
    Timer.periodic(const Duration(seconds: 1), (timer) {
      timeLeft--;
      if (mounted) {
        setState(() {});
      }
      if (timeLeft <= 0) {
        timer.cancel();
      }
    });
  }
}
