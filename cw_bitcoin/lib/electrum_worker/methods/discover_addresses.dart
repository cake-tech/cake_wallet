part of 'methods.dart';

class ElectrumWorkerDiscoverAddressesRequest implements ElectrumWorkerRequest {
  ElectrumWorkerDiscoverAddressesRequest({
    required this.count,
    required this.startIndex,
    required this.seedBytesType,
    required this.walletType,
    required this.derivationInfo,
    required this.isChange,
    required this.addressType,
    required this.xpriv,
    required this.network,
    this.id,
    this.completed = false,
  });

  final int? id;
  final bool completed;

  final int count;
  final int startIndex;

  final WalletType walletType;
  final SeedBytesType seedBytesType;
  final BitcoinDerivationInfo derivationInfo;
  final bool isChange;
  final BitcoinAddressType addressType;
  final String xpriv;
  final BasedUtxoNetwork network;

  @override
  final String method = ElectrumWorkerMethods.discoverAddresses.method;

  @override
  factory ElectrumWorkerDiscoverAddressesRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerDiscoverAddressesRequest(
      id: json['id'] as int,
      count: json['count'] as int,
      startIndex: json['startIndex'] as int,
      walletType: deserializeFromInt(json['walletType'] as int),
      seedBytesType: SeedBytesType.fromValue(json['seedBytesType'] as String),
      derivationInfo:
          BitcoinDerivationInfo.fromJSON(json['derivationInfo'] as Map<String, dynamic>),
      isChange: json['isChange'] as bool,
      addressType: BitcoinAddressType.fromValue(json['addressType'] as String),
      xpriv: json['xpriv'] as String,
      network: BasedUtxoNetwork.fromName(json['network'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'id': id,
      'completed': completed,
      'count': count,
      'startIndex': startIndex,
      'walletType': serializeToInt(walletType),
      'seedBytesType': seedBytesType.value,
      'isChange': isChange,
      'addressType': addressType.value,
      'xpriv': xpriv,
      'network': network.value,
      'derivationInfo': derivationInfo.toJSON(),
    };
  }
}

class ElectrumWorkerDiscoverAddressesErrorResponse extends ElectrumWorkerErrorResponse {
  ElectrumWorkerDiscoverAddressesErrorResponse({
    required super.error,
    super.id,
  });

  @override
  final String method = ElectrumWorkerMethods.discoverAddresses.method;
}

class ElectrumWorkerDiscoverAddressesResponse
    extends ElectrumWorkerResponse<List<BitcoinAddressRecord>, List<String>> {
  ElectrumWorkerDiscoverAddressesResponse({
    required List<BitcoinAddressRecord> addresses,
    super.error,
    super.id,
    super.completed,
  }) : super(
          result: addresses,
          method: ElectrumWorkerMethods.discoverAddresses.method,
        );

  @override
  List<String> resultJson(List<BitcoinAddressRecord> result) {
    return result.map((e) => e.toJSON()).toList();
  }

  @override
  factory ElectrumWorkerDiscoverAddressesResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerDiscoverAddressesResponse(
      error: json['error'] as String?,
      id: json['id'] as int?,
      addresses: (json['result'] as List)
          .map((addr) => BitcoinAddressRecord.fromJSON(addr as String))
          .toList(),
    );
  }
}
