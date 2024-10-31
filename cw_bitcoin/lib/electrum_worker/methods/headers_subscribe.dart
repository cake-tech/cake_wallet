part of 'methods.dart';

class ElectrumWorkerHeadersSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerHeadersSubscribeRequest();

  @override
  final String method = ElectrumRequestMethods.headersSubscribe.method;

  @override
  factory ElectrumWorkerHeadersSubscribeRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerHeadersSubscribeRequest();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method};
  }
}

class ElectrumWorkerHeadersSubscribeError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerHeadersSubscribeError({required String error}) : super(error: error);

  @override
  final String method = ElectrumRequestMethods.headersSubscribe.method;
}

class ElectrumWorkerHeadersSubscribeResponse
    extends ElectrumWorkerResponse<ElectrumHeaderResponse, Map<String, dynamic>> {
  ElectrumWorkerHeadersSubscribeResponse({required super.result, super.error})
      : super(method: ElectrumRequestMethods.headersSubscribe.method);

  @override
  Map<String, dynamic> resultJson(result) {
    return result.toJson();
  }

  @override
  factory ElectrumWorkerHeadersSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerHeadersSubscribeResponse(
      result: ElectrumHeaderResponse.fromJson(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );
  }
}
