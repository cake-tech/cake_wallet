class PhoneNumberService {
  const PhoneNumberService({
    this.id,
    this.phoneNumber,
    this.planId,
    this.usedUntil,
    this.messageReceiveEnabled,
    this.autoRenew,
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
