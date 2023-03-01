
enum ReceivePageOption {
  mainnet,
  anonPayInvoice,
  anonPayDonationLink;

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
