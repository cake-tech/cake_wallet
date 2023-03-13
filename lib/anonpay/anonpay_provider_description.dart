import 'package:cw_core/enumerable_item.dart';

class AnonpayProviderDescription extends EnumerableItem<int> with Serializable<int> {
  const AnonpayProviderDescription({required String title, required int raw})
      : super(title: title, raw: raw);

  static const anonpayInvoice =
      AnonpayProviderDescription(title: 'Trocador AnonPay Invoice', raw: 0);

  static const anonpayDonationLink =
      AnonpayProviderDescription(title: 'Trocador AnonPay Donation Link', raw: 1);

  static AnonpayProviderDescription deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return anonpayInvoice;
      case 1:
        return anonpayDonationLink;
      default:
        throw Exception('Incorrect token $raw  for AnonapyProviderDescription deserialize');
    }
  }
}
