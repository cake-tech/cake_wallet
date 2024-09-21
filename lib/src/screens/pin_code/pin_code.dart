import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';

class PinCode extends PinCodeWidget {
  PinCode(
      void Function(String pin, PinCodeState state) onFullPin,
      void Function(String pin) onChangedPin,
      void Function(bool) setPinRandomized,
      int initialPinLength,
      bool initialPinRandomized,
      bool hasLengthSwitcher,
      Key key)
      : super(
          key: key,
          onFullPin: onFullPin,
          onChangedPin: onChangedPin,
          hasLengthSwitcher: hasLengthSwitcher,
          initialPinLength: initialPinLength,
          initialPinRandomized: initialPinRandomized,
          setPinRandomized: setPinRandomized,
        );

  @override
  PinCodeState createState() => PinCodeState();
}
