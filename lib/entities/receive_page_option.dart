enum ReceivePageOption {
  mainnet,
  anonPayInvoice,
  anonPayDonationLink;

  @override
  String toString() {
    String label = '';
    switch (this) {
      case ReceivePageOption.mainnet:
        label = S.current.mainnet;
        break;
      case ReceivePageOption.anonPayInvoice:
        label = S.current.trocador_anonpay_invoice;
        break;
      case ReceivePageOption.anonPayDonationLink:
        label = S.current.trocador_anonpay_donation_link;
        break;
    }
    return label;
  }
}
