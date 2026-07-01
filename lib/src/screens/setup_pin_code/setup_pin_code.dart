import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/view_model/setup_pin_code_view_model.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

class SetupPinCodePage extends BasePage {
  SetupPinCodePage(this.pinCodeViewModel,{this.onSuccessfulPinSetup, this.isDuressPin = false})
      : pinCodeStateKey = GlobalKey<PinCodeState>();

  final SetupPinCodeViewModel pinCodeViewModel;
  final void Function(PinCodeState<PinCodeWidget>, String)? onSuccessfulPinSetup;
  final bool isDuressPin;
  final GlobalKey<PinCodeState> pinCodeStateKey;

  @override
  String get title => isDuressPin ? S.current.durres_PIN : S.current.setup_pin;

  @override
  Widget body(BuildContext context) => PinCodeWidget(
      key: pinCodeStateKey,
      hasLengthSwitcher: true,
      onFullPin: (String pin, PinCodeState<PinCodeWidget> state) async {
        if (pinCodeViewModel.isOriginalPinCodeFull &&
            !pinCodeViewModel.isRepeatedPinCodeFull) {
          state.title = S.current.enter_your_pin_again;
          state.clear();
          return;
        }

        if (!pinCodeViewModel.isPinCodeCorrect) {
          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.current.setup_pin,
                    alertContent: S.of(context).pin_is_incorrect,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
          pinCodeViewModel.reset();
          state.reset();
          return;
        }

        try {
          await pinCodeViewModel.setupPinCode();

          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  buttonKey: ValueKey('setup_pin_code_success_button_key'),
                  alertTitle: isDuressPin ? S.current.durres_PIN : S.current.setup_pin,
                  alertContent: isDuressPin
                      ? S.current.durres_PIN_set_up_successfully
                      : S.current.setup_successful,
                  buttonText: S.of(context).ok,
                  buttonAction: () {
                    Navigator.of(context).pop();
                    if (pinCodeStateKey.currentState != null) {
                      onSuccessfulPinSetup?.call(pinCodeStateKey.currentState!, pin);
                    }
                    
                    state.reset();
                  },
                  alertBarrierDismissible: false,
                );
              });
        } catch (e) {
          await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  alertTitle: isDuressPin ? S.current.durres_PIN : S.current.setup_pin,
                  alertContent:
                      '${S.current.setup_pin_is_failed} ${e.toString()}',
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop(),
                  alertBarrierDismissible: false,
                );
              });
        }
      },
      onChangedPin: (String pin) async {
        try {
          await pinCodeViewModel.setPinCode(pin);
        } catch (e) {
          await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                alertTitle: S.current.durres_PIN,
                alertContent: e.toString(),
                buttonText: S.of(context).ok,
                buttonAction: () {
                  Navigator.of(context).pop();
                },
                alertBarrierDismissible: false,
              );
            },
          );

          pinCodeStateKey.currentState?.reset();
          pinCodeViewModel.reset();
        }
      },
      onChangedPinLength: (int length) =>
          pinCodeViewModel.pinCodeLength = length,
      initialPinLength: pinCodeViewModel.pinCodeLength);
}
