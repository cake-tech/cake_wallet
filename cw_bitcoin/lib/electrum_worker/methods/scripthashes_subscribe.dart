part of 'methods.dart';

class ElectrumWorkerScripthashesSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerScripthashesSubscribeRequest({
    required this.scripthashByAddress,
    required this.addressByScripthashes,
    this.id,
    this.completed = false,
  });

  final Map<String, String> scripthashByAddress;
  final Map<String, String> addressByScripthashes;
  final int? id;
  final bool completed;

  @override
  final String method = ElectrumRequestMethods.scriptHashSubscribe.method;

  @override
  factory ElectrumWorkerScripthashesSubscribeRequest.fromJson(Map<dynamic, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeRequest(
      scripthashByAddress: json['scripthashByAddress'] as Map<String, String>,
      addressByScripthashes: json['addressByScripthashes'] as Map<String, String>,
      id: json['id'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'id': id,
      'completed': completed,
      'scripthashByAddress': scripthashByAddress,
      'addressByScripthashes': addressByScripthashes,
    };
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

class ElectrumWorkerScripthashesResponse {
  ElectrumWorkerScripthashesResponse({
    required this.address,
    required this.scripthash,
    this.status,
  });

  final String address;
  final String scripthash;
  final String? status;

  Map<String, dynamic> toJson() {
    return {'address': address, 'scripthash': scripthash, 'status': status};
  }

  static ElectrumWorkerScripthashesResponse fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesResponse(
      address: json['address'] as String? ?? '',
      scripthash: json['scripthash'] as String? ?? '',
      status: json['status'] as String?,
    );
  }
}

class ElectrumWorkerScripthashesSubscribeResponse extends ElectrumWorkerResponse<
    List<ElectrumWorkerScripthashesResponse>, List<Map<String, dynamic>>> {
  ElectrumWorkerScripthashesSubscribeResponse({
    required super.result,
    super.error,
    super.id,
    super.completed,
  }) : super(method: ElectrumRequestMethods.scriptHashSubscribe.method);

  @override
  List<Map<String, dynamic>> resultJson(result) {
    return result.map((e) => e.toJson()).toList();
  }

  @override
  factory ElectrumWorkerScripthashesSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerScripthashesSubscribeResponse(
      result: (json['result'] as List<dynamic>).map((e) {
        if (e is String) {
          return ElectrumWorkerScripthashesResponse.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          );
        }

        return ElectrumWorkerScripthashesResponse.fromJson(
          e as Map<String, dynamic>,
        );
      }).toList(),
      error: json['error'] as String?,
      id: json['id'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
