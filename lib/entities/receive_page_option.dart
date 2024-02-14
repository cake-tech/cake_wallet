enum ReceivePageOption {
  mainnet,
  anonPayInvoice,
  anonPayDonationLink,
  lightningInvoice,
  lightningOnchain;

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
      case ReceivePageOption.lightningInvoice:
        label = 'Sats via Invoice';
        break;
      case ReceivePageOption.lightningOnchain:
        label = 'Sats via BTC address';
        break;
    }
    return label;
  }
}
