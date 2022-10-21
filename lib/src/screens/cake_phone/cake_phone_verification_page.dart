import 'dart:async';

import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class CakePhoneVerificationPage extends BasePage {
  CakePhoneVerificationPage();

  @override
  Widget body(BuildContext context) => CakePhoneVerificationBody();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).email_verification,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.headline6?.decorationColor),
    );
  }
}

class CakePhoneVerificationBody extends StatefulWidget {
  CakePhoneVerificationBody();

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
                  color: Theme.of(context).primaryTextTheme.headline6?.color,
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
                                color: Theme.of(context).accentTextTheme.caption?.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                S.of(context).get_code,
                                style: TextStyle(
                                  color: Theme.of(context).primaryTextTheme.headline6?.color,
                                  fontWeight: FontWeight.w900,
                                ),
                              )),
                        ),
                  validator: (String? text) {
                    // TODO: check and apply verification constraints with backend
                    if ((text?.length ?? 0) < 4) {
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
                      color: Theme.of(context).textTheme.subtitle2?.color,
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
                if (_formKey.currentState!.validate()) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.cakePhoneProducts,
                    ModalRoute.withName(Routes.cakePhoneWelcome),
                  );
                } else {
                  setState(() {
                    _autoValidate = AutovalidateMode.always;
                  });
                }
              },
              text: S.of(context).continue_text,
              color: Theme.of(context).accentTextTheme.bodyText1?.color,
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
