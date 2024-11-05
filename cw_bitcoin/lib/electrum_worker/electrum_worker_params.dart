// import 'dart:convert';

import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';

abstract class ElectrumWorkerRequest {
  abstract final String method;
  abstract final int? id;

  Map<String, dynamic> toJson();
  ElectrumWorkerRequest.fromJson(Map<String, dynamic> json);
}

class ElectrumWorkerResponse<RESULT, RESPONSE> {
  ElectrumWorkerResponse({
    required this.method,
    required this.result,
    this.error,
    this.id,
  });

  final String method;
  final RESULT result;
  final String? error;
  final int? id;

  RESPONSE resultJson(RESULT result) {
    throw UnimplementedError();
  }

  factory ElectrumWorkerResponse.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    return {'method': method, 'result': resultJson(result), 'error': error, 'id': id};
  }
}

class ElectrumWorkerErrorResponse {
  ElectrumWorkerErrorResponse({required this.error, this.id});

  String get method => ElectrumWorkerMethods.unknown.method;
  final int? id;
  final String error;

  factory ElectrumWorkerErrorResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerErrorResponse(error: json['error'] as String, id: json['id'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'method': method, 'error': error, 'id': id};
  }
}
