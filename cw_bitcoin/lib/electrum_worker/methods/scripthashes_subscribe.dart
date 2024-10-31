part of 'methods.dart';

class ElectrumWorkerScripthashesSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerScripthashesSubscribeRequest({required this.scripthashByAddress});

  final Map<String, String> scripthashByAddress;

  @override
  final String method = ElectrumRequestMethods.scriptHashSubscribe.method;

  @override
  factory ElectrumWorkerScripthashesSubscribeRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeRequest(
      scripthashByAddress: json['scripthashes'] as Map<String, String>,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'scripthashes': scripthashByAddress};
  }
}

class ElectrumWorkerScripthashesSubscribeError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerScripthashesSubscribeError({required String error}) : super(error: error);

  @override
  final String method = ElectrumRequestMethods.scriptHashSubscribe.method;
}

class ElectrumWorkerScripthashesSubscribeResponse
    extends ElectrumWorkerResponse<Map<String, String>?, Map<String, String>?> {
  ElectrumWorkerScripthashesSubscribeResponse({required super.result, super.error})
      : super(method: ElectrumRequestMethods.scriptHashSubscribe.method);

  @override
  Map<String, String>? resultJson(result) {
    return result;
  }

  @override
  factory ElectrumWorkerScripthashesSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeResponse(
      result: json['result'] as Map<String, String>?,
      error: json['error'] as String?,
    );
  }
}
