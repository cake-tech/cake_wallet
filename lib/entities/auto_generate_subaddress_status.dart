
enum AutoGenerateSubaddressStatus { 
  initialized(1), 
  enabled(2), 
  disabled(3);

  const AutoGenerateSubaddressStatus(this.value);
  final int value;

  static AutoGenerateSubaddressStatus deserialize({required int raw}) => 
      AutoGenerateSubaddressStatus.values.firstWhere((e) => e.value == raw);
  
}