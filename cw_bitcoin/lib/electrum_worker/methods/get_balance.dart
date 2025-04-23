part of 'methods.dart';

class ElectrumWorkerGetBalanceRequest implements ElectrumWorkerRequest {
  ElectrumWorkerGetBalanceRequest({
    required this.scripthashes,
    this.id,
    this.completed = false,
  });

  final List<String> scripthashes;
  final int? id;
  final bool completed;

  @override
  final String method = ElectrumRequestMethods.getBalance.method;

  @override
  factory ElectrumWorkerGetBalanceRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetBalanceRequest(
      scripthashes: json['scripthashes'] as List<String>,
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
      'scripthashes': scripthashes.toList(),
    };
  }
}

class ElectrumWorkerGetBalanceError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerGetBalanceError({
    required super.error,
    super.id,
  }) : super();

  @override
  final String method = ElectrumRequestMethods.getBalance.method;
}

class ElectrumGetBalanceResponse {
  ElectrumGetBalanceResponse({
    required this.balances,
    required this.scripthashes,
  });

  final List<ElectrumBalance> balances;
  final List<String> scripthashes;

  Map<String, dynamic> toJson() {
    return {
      'balances': balances
          .map((e) => {
                'confirmed': e.confirmed,
                'unconfirmed': e.unconfirmed,
                'frozen': e.frozen,
              })
          .toList(),
      'scripthashes': scripthashes,
    };
  }

  factory ElectrumGetBalanceResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumGetBalanceResponse(
      balances: (json['balances'] as List)
          .map((e) => ElectrumBalance(
                confirmed: e['confirmed'] as int,
                unconfirmed: e['unconfirmed'] as int,
                frozen: e['frozen'] as int,
              ))
          .toList(),
      scripthashes: (json['scripthashes'] as List).cast<String>(),
    );
  }
}

class ElectrumWorkerGetBalanceResponse
    extends ElectrumWorkerResponse<ElectrumGetBalanceResponse, Map<String, dynamic>> {
  ElectrumWorkerGetBalanceResponse({
    required super.result,
    super.error,
    super.id,
    super.completed,
  }) : super(method: ElectrumRequestMethods.getBalance.method);

  @override
  Map<String, dynamic> resultJson(result) {
    return result.toJson();
  }

  @override
  factory ElectrumWorkerGetBalanceResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetBalanceResponse(
      result: ElectrumGetBalanceResponse.fromJson(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
      id: json['id'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
