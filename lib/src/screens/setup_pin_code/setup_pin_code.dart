import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/user/user_store.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/widgets/pin_alert_dialog.dart';

class SetupPinCodePage extends BasePage {
  SetupPinCodePage({this.onPinCodeSetup});

  final Function(BuildContext, String) onPinCodeSetup;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  String get title => S.current.setup_pin;

  @override
  Widget body(BuildContext context) =>
      SetupPinCodeForm(onPinCodeSetup: onPinCodeSetup, hasLengthSwitcher: true);
}

class SetupPinCodeForm extends PinCodeWidget {
  SetupPinCodeForm(
      {@required this.onPinCodeSetup, @required bool hasLengthSwitcher})
      : super(hasLengthSwitcher: hasLengthSwitcher);

  final Function(BuildContext, String) onPinCodeSetup;

  @override
  _SetupPinCodeFormState createState() => _SetupPinCodeFormState();
}

class _SetupPinCodeFormState<WidgetType extends SetupPinCodeForm>
    extends PinCodeState<WidgetType> {
  _SetupPinCodeFormState() {
    title = S.current.enter_your_pin;
  }

  bool isEnteredOriginalPin() => _originalPin.isNotEmpty;
  Function(BuildContext) onPinCodeSetup;
  List<int> _originalPin = [];
  UserStore _userStore;
  SettingsStore _settingsStore;

  @override
  void onPinCodeEntered(PinCodeState state) {
    if (!isEnteredOriginalPin()) {
      _originalPin = state.pin;
      state.title = S.current.enter_your_pin_again;
      state.clear();
    } else {
      if (listEquals<int>(state.pin, _originalPin)) {
        final String pin = state.pin.fold("", (ac, val) => ac + '$val');
        _userStore.set(password: pin);
        _settingsStore.setDefaultPinLength(pinLength: state.pinLength);

        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return PinAlertDialog(
                  pinTitleText: S.current.setup_pin,
                  pinContentText: S.of(context).setup_successful,
                  pinActionButtonText: S.of(context).ok,
                  pinBarrierDismissible: false,
                  pinAction: () {
                    Navigator.of(context).pop();
                    widget.onPinCodeSetup(context, pin);
                    reset();
                  });
            });
      } else {
        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return PinAlertDialog(
                  pinTitleText: S.current.setup_pin,
                  pinContentText: S.of(context).pin_is_incorrect,
                  pinActionButtonText: S.of(context).ok,
                  pinBarrierDismissible: true,
                  pinAction: () => Navigator.of(context).pop());
            });

        reset();
      }
    }
  }

  void reset() {
    clear();
    setTitle(S.current.enter_your_pin);
    _originalPin = [];
  }

  @override
  Widget build(BuildContext context) {
    _userStore = Provider.of<UserStore>(context);
    _settingsStore = Provider.of<SettingsStore>(context);

    return body(context);
  }
}
