import 'package:cake_wallet/generated/i18n.dart';

enum ReceivePageOption {
  mainnet(1),
  anonPayInvoice(2),
  anonPayDonationLink(3);

  const ReceivePageOption(this.raw);
  final int raw;

  static ReceivePageOption deserialize({required int raw}) =>
      ReceivePageOption.values.firstWhere((e) => e.raw == raw);

  @override
  String toString() {
    String label = '';
    switch (this) {
      case ReceivePageOption.mainnet:
        label = 'Mainnet';
        break;
      case ReceivePageOption.anonPayInvoice:
        label = 'Trocador AnonPay Invoice';
        break;
      case ReceivePageOption.anonPayDonationLink:
        label = 'Trocador AnonPay Donation Link';
        break;
    }
    return label;
  }
}
