part of 'methods.dart';

class ScanData {
  final List<SilentPaymentOwner> silentPaymentsWallets;
  final int height;
  final BasedUtxoNetwork network;
  final int chainTip;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;

  ScanData({
    required this.silentPaymentsWallets,
    required this.height,
    required this.network,
    required this.chainTip,
    required this.transactionHistoryIds,
    required this.labels,
    required this.labelIndexes,
    required this.isSingleScan,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) {
    return ScanData(
      silentPaymentsWallets: scanData.silentPaymentsWallets,
      height: newHeight,
      network: scanData.network,
      chainTip: scanData.chainTip,
      transactionHistoryIds: scanData.transactionHistoryIds,
      labels: scanData.labels,
      labelIndexes: scanData.labelIndexes,
      isSingleScan: scanData.isSingleScan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'silentAddress': silentPaymentsWallets.map((e) => e.toJson()).toList(),
      'height': height,
      'network': network.value,
      'chainTip': chainTip,
      'transactionHistoryIds': transactionHistoryIds,
      'labels': labels,
      'labelIndexes': labelIndexes,
      'isSingleScan': isSingleScan,
    };
  }

  static ScanData fromJson(Map<String, dynamic> json) {
    return ScanData(
      silentPaymentsWallets: (json['silentAddress'] as List)
          .map((e) => SilentPaymentOwner.fromJson(e as Map<String, dynamic>))
          .toList(),
      height: json['height'] as int,
      network: BasedUtxoNetwork.fromName(json['network'] as String),
      chainTip: json['chainTip'] as int,
      transactionHistoryIds:
          (json['transactionHistoryIds'] as List).map((e) => e as String).toList(),
      labels: json['labels'] as Map<String, String>,
      labelIndexes: (json['labelIndexes'] as List).map((e) => e as int).toList(),
      isSingleScan: json['isSingleScan'] as bool,
    );
  }
}

class ElectrumWorkerTweaksSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerTweaksSubscribeRequest({
    required this.scanData,
    this.id,
  });

  final ScanData scanData;
  final int? id;

  @override
  final String method = ElectrumRequestMethods.tweaksSubscribe.method;

  @override
  factory ElectrumWorkerTweaksSubscribeRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerTweaksSubscribeRequest(
      scanData: ScanData.fromJson(json['scanData'] as Map<String, dynamic>),
      id: json['id'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'scanData': scanData.toJson()};
  }
}

class ElectrumWorkerTweaksSubscribeError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerTweaksSubscribeError({
    required super.error,
    super.id,
  }) : super();

  @override
  final String method = ElectrumRequestMethods.tweaksSubscribe.method;
}

class TweaksSyncResponse {
  int? height;
  SyncStatus? syncStatus;
  Map<String, ElectrumTransactionInfo>? transactions = {};

  TweaksSyncResponse({this.height, this.syncStatus, this.transactions});

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'syncStatus': syncStatus == null ? null : syncStatusToJson(syncStatus!),
      'transactions': transactions?.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  static TweaksSyncResponse fromJson(Map<String, dynamic> json) {
    return TweaksSyncResponse(
      height: json['height'] as int?,
      syncStatus: json['syncStatus'] == null
          ? null
          : syncStatusFromJson(json['syncStatus'] as Map<String, dynamic>),
      transactions: json['transactions'] == null
          ? null
          : (json['transactions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                ElectrumTransactionInfo.fromJson(value as Map<String, dynamic>, WalletType.bitcoin),
              ),
            ),
    );
  }
}

class ElectrumWorkerTweaksSubscribeResponse
    extends ElectrumWorkerResponse<TweaksSyncResponse, Map<String, dynamic>> {
  ElectrumWorkerTweaksSubscribeResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumRequestMethods.tweaksSubscribe.method);

  @override
  Map<String, dynamic> resultJson(result) {
    return result.toJson();
  }

  @override
  factory ElectrumWorkerTweaksSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerTweaksSubscribeResponse(
      result: TweaksSyncResponse.fromJson(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
