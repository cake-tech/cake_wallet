part of 'methods.dart';

class ElectrumWorkerScripthashesSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerScripthashesSubscribeRequest({
    required this.scripthashByAddress,
    this.id,
  });

  final Map<String, String> scripthashByAddress;
  final int? id;

  @override
  final String method = ElectrumRequestMethods.scriptHashSubscribe.method;

  @override
  factory ElectrumWorkerScripthashesSubscribeRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeRequest(
      scripthashByAddress: json['scripthashes'] as Map<String, String>,
      id: json['id'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'scripthashes': scripthashByAddress};
  }
}

class ElectrumWorkerScripthashesSubscribeError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerScripthashesSubscribeError({
    required super.error,
    super.id,
  }) : super();

  @override
  final String method = ElectrumRequestMethods.scriptHashSubscribe.method;
}

class ElectrumWorkerScripthashesSubscribeResponse
    extends ElectrumWorkerResponse<Map<String, String>?, Map<String, String>?> {
  ElectrumWorkerScripthashesSubscribeResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumRequestMethods.scriptHashSubscribe.method);

  @override
  Map<String, String>? resultJson(result) {
    return result;
  }

  @override
  factory ElectrumWorkerScripthashesSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeResponse(
      result: json['result'] as Map<String, String>?,
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
