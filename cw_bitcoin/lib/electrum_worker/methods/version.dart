part of 'methods.dart';

class ElectrumWorkerGetVersionRequest implements ElectrumWorkerRequest {
  ElectrumWorkerGetVersionRequest({this.id});

  final int? id;

  @override
  final String method = ElectrumRequestMethods.version.method;

  @override
  factory ElectrumWorkerGetVersionRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetVersionRequest(id: json['id'] as int?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method};
  }
}

class ElectrumWorkerGetVersionError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerGetVersionError({
    required super.error,
    super.id,
  }) : super();

  @override
  String get method => ElectrumRequestMethods.version.method;
}

class ElectrumWorkerGetVersionResponse extends ElectrumWorkerResponse<List<String>, List<String>> {
  ElectrumWorkerGetVersionResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumRequestMethods.version.method);

  @override
  List<String> resultJson(result) {
    return result;
  }

  @override
  factory ElectrumWorkerGetVersionResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetVersionResponse(
      result: json['result'] as List<String>,
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
