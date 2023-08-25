import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/totp_request_details.dart';
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../palette.dart';
import '../../../routes.dart';

class TotpAuthCodePage extends BasePage {
  TotpAuthCodePage({required this.setup2FAViewModel, required TotpAuthArgumentsModel totpArguments})
      : isForSetup = totpArguments.isForSetup ?? false,
        isClosable = totpArguments.isClosable ?? true,
        showPopup = totpArguments.isForSetup ?? totpArguments.showPopup ?? false,
        onTotpAuthenticationFinished = totpArguments.onTotpAuthenticationFinished,
        totpController = TextEditingController() {
    totpController.addListener(() {
      setup2FAViewModel.enteredOTPCode = totpController.text;
    });
  }

  final TextEditingController totpController;
  final Setup2FAViewModel setup2FAViewModel;
  final bool isForSetup;
  final bool isClosable;
  final bool showPopup;
  final Function(TotpResponse)? onTotpAuthenticationFinished;

  @override
  String get title => isForSetup ? S.current.setup_2fa : S.current.verify_with_2fa;

  @override
  Widget? leading(BuildContext context) {
    return isClosable ? super.leading(context) : null;
  }

  @override
  Widget body(BuildContext context) {
    Future<void> close({String? route, dynamic arguments}) async {
      if (route != null) {
        Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
      } else {
        Navigator.of(context).pop();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          BaseTextFormField(
            textAlign: TextAlign.left,
            hintText: S.current.totp_code,
            controller: totpController,
            keyboardType: TextInputType.number,
            placeholderTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text(
            S.current.please_fill_totp,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: Palette.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          Observer(
            builder: (_) {
              return LoadingPrimaryButton(
                isDisabled: setup2FAViewModel.enteredOTPCode.length != 8 ||
                    setup2FAViewModel.state is IsExecutingState,
                isLoading: setup2FAViewModel.state is IsExecutingState,
                onPressed: () async {
                  final result =
                      await setup2FAViewModel.totp2FAAuth(totpController.text, isForSetup);

                  if (showPopup || result == false) {
                    final bannedState = setup2FAViewModel.state is AuthenticationBanned;
                    await showPopUp<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return PopUpCancellableAlertDialog(
                          contentText: _textDisplayedInPopupOnResult(result, bannedState, context),
                          actionButtonText: S.of(context).ok,
                          buttonAction: () {
                            result
                                ? onTotpAuthenticationFinished
                                    ?.call(TotpResponse(success: true, close: close))
                                : null;

                            if (isForSetup && result) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, Routes.dashboard, (route) => false);
                            } else {
                              Navigator.of(context).pop(result);
                            }
                          },
                        );
                      },
                    );
                  }

                  if (showPopup == false) {
                    result
                        ? onTotpAuthenticationFinished
                            ?.call(TotpResponse(success: true, close: close))
                        : null;
                  }
                },
                text: S.of(context).continue_text,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
              );
            },
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  String _textDisplayedInPopupOnResult(bool result, bool bannedState, BuildContext context) {
    switch (result) {
      case true:
        return isForSetup ? S.current.totp_2fa_success : S.current.totp_verification_success;
      case false:
        if (bannedState) {
          final state = setup2FAViewModel.state as AuthenticationBanned;
          return S.of(context).failed_authentication(state.error);
        } else {
          return S.current.totp_2fa_failure;
        }
      default:
        return S.current.enter_totp_code;
    }
  }
}
