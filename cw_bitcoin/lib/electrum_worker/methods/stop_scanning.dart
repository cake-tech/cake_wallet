part of 'methods.dart';

class ElectrumWorkerStopScanningRequest implements ElectrumWorkerRequest {
  ElectrumWorkerStopScanningRequest({this.id});

  final int? id;

  @override
  final String method = ElectrumWorkerMethods.stopScanning.method;

  @override
  factory ElectrumWorkerStopScanningRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerStopScanningRequest(id: json['id'] as int?);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'id': id};
  }
}

class ElectrumWorkerStopScanningError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerStopScanningError({required super.error, super.id}) : super();

  @override
  final String method = ElectrumWorkerMethods.stopScanning.method;
}

class ElectrumWorkerStopScanningResponse extends ElectrumWorkerResponse<bool, String> {
  ElectrumWorkerStopScanningResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumWorkerMethods.stopScanning.method);

  @override
  String resultJson(result) {
    return result.toString();
  }

  @override
  factory ElectrumWorkerStopScanningResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerStopScanningResponse(
      result: json['result'] as bool,
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
