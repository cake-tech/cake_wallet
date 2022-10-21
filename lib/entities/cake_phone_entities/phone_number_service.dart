class PhoneNumberService {
  const PhoneNumberService({
    required this.id,
    required this.phoneNumber,
    required this.planId,
    required this.usedUntil,
    this.messageReceiveEnabled = false,
    this.autoRenew = false,
  });

  final String id;
  final String phoneNumber;
  final String planId;
  final DateTime usedUntil;
  final bool messageReceiveEnabled;
  final bool autoRenew;

  @override
  bool operator ==(Object other) => other is PhoneNumberService && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
