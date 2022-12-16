import 'package:cake_wallet/generated/i18n.dart';

enum PinCodeRequiredDuration { 
  always(0), 
  tenminutes(10), 
  onehour(60);

  const PinCodeRequiredDuration(this.value);
  final int value;

  static PinCodeRequiredDuration deserialize({required int raw}) => 
      PinCodeRequiredDuration.values.firstWhere((e) => e.value == raw);

  @override
  String toString(){
    String label = '';
    switch (this) {
      case PinCodeRequiredDuration.always:
        label = S.current.always;
        break;
      case PinCodeRequiredDuration.tenminutes:
        label = S.current.minutes_to_pin_code('10');
        break;
      case PinCodeRequiredDuration.onehour:
        label = S.current.minutes_to_pin_code('60');
        break;
    }
    return label;

  }
  
}