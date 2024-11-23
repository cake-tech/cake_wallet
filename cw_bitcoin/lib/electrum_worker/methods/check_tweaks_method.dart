part of 'methods.dart';

class ElectrumWorkerCheckTweaksRequest implements ElectrumWorkerRequest {
  ElectrumWorkerCheckTweaksRequest({this.id});

  final int? id;

  @override
  final String method = ElectrumWorkerMethods.checkTweaks.method;

  @override
  factory ElectrumWorkerCheckTweaksRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerCheckTweaksRequest(id: json['id'] as int?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'id': id};
  }
}

class ElectrumWorkerCheckTweaksError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerCheckTweaksError({required super.error, super.id}) : super();

  @override
  final String method = ElectrumWorkerMethods.checkTweaks.method;
}

class ElectrumWorkerCheckTweaksResponse extends ElectrumWorkerResponse<bool, String> {
  ElectrumWorkerCheckTweaksResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumWorkerMethods.checkTweaks.method);

  @override
  String resultJson(result) {
    return result.toString();
  }

  @override
  factory ElectrumWorkerCheckTweaksResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerCheckTweaksResponse(
      result: json['result'] == "true",
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
