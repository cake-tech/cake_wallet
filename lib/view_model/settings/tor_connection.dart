enum TorConnectionType { enabled, disabled, onionOnly }

class TorConnection {
  TorConnection(this.name, this.type);

  final String name;
  final TorConnectionType type;

  static final all = [
    TorConnection("Enabled", TorConnectionType.enabled),
    TorConnection("Disabled", TorConnectionType.disabled),
    TorConnection("Onion Only", TorConnectionType.onionOnly),
  ];
}
