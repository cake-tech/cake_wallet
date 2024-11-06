part of 'methods.dart';

class ElectrumWorkerGetFeesRequest implements ElectrumWorkerRequest {
  ElectrumWorkerGetFeesRequest({
    required this.mempoolAPIEnabled,
    this.id,
  });

  final bool mempoolAPIEnabled;
  final int? id;

  @override
  final String method = ElectrumRequestMethods.estimateFee.method;

  @override
  factory ElectrumWorkerGetFeesRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetFeesRequest(
      mempoolAPIEnabled: json['mempoolAPIEnabled'] as bool,
      id: json['id'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'mempoolAPIEnabled': mempoolAPIEnabled};
  }
}

class ElectrumWorkerGetFeesError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerGetFeesError({
    required super.error,
    super.id,
  }) : super();

  @override
  String get method => ElectrumRequestMethods.estimateFee.method;
}

class ElectrumWorkerGetFeesResponse
    extends ElectrumWorkerResponse<TransactionPriorities, Map<String, int>> {
  ElectrumWorkerGetFeesResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumRequestMethods.estimateFee.method);

  @override
  Map<String, int> resultJson(result) {
    return result.toJson();
  }

  @override
  factory ElectrumWorkerGetFeesResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetFeesResponse(
      result: deserializeTransactionPriorities(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
