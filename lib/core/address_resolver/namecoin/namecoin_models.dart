class NamecoinElectrumServer {
  const NamecoinElectrumServer(this.host, this.port, {this.useSsl = true});

  final String host;
  final int port;
  final bool useSsl;

  String get label => '$host:$port';
}

const defaultNamecoinElectrumServers = <NamecoinElectrumServer>[
  NamecoinElectrumServer('electrumx.testls.space', 50002),
  NamecoinElectrumServer('nmc2.bitcoins.sk', 57002),
  NamecoinElectrumServer('electrumx2.testls.space', 50012),
];

class NamecoinLookup {
  const NamecoinLookup({
    required this.name,
    required this.value,
    required this.txid,
    required this.height,
    required this.expiresIn,
  });

  final String name;
  final String value;
  final String txid;
  final int height;
  final int expiresIn;
}

class NamecoinResolutionException implements Exception {
  const NamecoinResolutionException(this.message);

  final String message;

  @override
  String toString() => 'NamecoinResolutionException: $message';
}

class NamecoinExpiredException extends NamecoinResolutionException {
  const NamecoinExpiredException(String name) : super('Namecoin name expired: $name');
}

class NamecoinRpcException extends NamecoinResolutionException {
  const NamecoinRpcException(super.message);
}
