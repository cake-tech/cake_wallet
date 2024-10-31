part of 'methods.dart';

class ElectrumWorkerConnectionRequest implements ElectrumWorkerRequest {
  ElectrumWorkerConnectionRequest({required this.uri});

  final Uri uri;

  @override
  final String method = ElectrumWorkerMethods.connect.method;

  @override
  factory ElectrumWorkerConnectionRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerConnectionRequest(uri: Uri.parse(json['params'] as String));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'params': uri.toString()};
  }
}

class ElectrumWorkerConnectionError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerConnectionError({required String error}) : super(error: error);

  @override
  String get method => ElectrumWorkerMethods.connect.method;
}

class ElectrumWorkerConnectionResponse extends ElectrumWorkerResponse<ConnectionStatus, String> {
  ElectrumWorkerConnectionResponse({required ConnectionStatus status, super.error})
      : super(
          result: status,
          method: ElectrumWorkerMethods.connect.method,
        );

  @override
  String resultJson(result) {
    return result.toString();
  }

  @override
  factory ElectrumWorkerConnectionResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerConnectionResponse(
      status: ConnectionStatus.values.firstWhere(
        (e) => e.toString() == json['result'] as String,
      ),
      error: json['error'] as String?,
    );
  }
}
