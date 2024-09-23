import 'package:cake_wallet/generated/i18n.dart';

enum PinCodeRequiredDuration {
  always(0),
  tenMinutes(10),
  halfHour(30),
  fortyFiveMinutes(45),
  oneHour(60);

  const PinCodeRequiredDuration(this.value);

  final int value;

  static PinCodeRequiredDuration deserialize({required int raw}) => 
      PinCodeRequiredDuration.values.firstWhere((e) => e.value == raw);

  @override
  String toString() {
    String label = '';
    switch (this) {
      case PinCodeRequiredDuration.always:
        label = S.current.always;
        break;
      case PinCodeRequiredDuration.tenMinutes:
        label = S.current.minutes_to_pin_code('10');
        break;
      case PinCodeRequiredDuration.oneHour:
        label = S.current.minutes_to_pin_code('60');
        break;
      case PinCodeRequiredDuration.halfHour:
        label = S.current.minutes_to_pin_code('30');
        break;
      case PinCodeRequiredDuration.fortyFiveMinutes:
        label = S.current.minutes_to_pin_code('45');
        break;
    }
    return label;
  }
}
