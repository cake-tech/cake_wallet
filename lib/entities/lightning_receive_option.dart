enum LightningReceiveOption {
  lightningInvoice,
  lightningOnchain;

  @override
  String toString() {
    String label = '';
    switch (this) {
      case LightningReceiveOption.lightningInvoice:
        label = 'Lightning via Invoice';
        break;
      case LightningReceiveOption.lightningOnchain:
        label = 'Lightning via BTC address';
        break;
    }
    return label;
  }
}
