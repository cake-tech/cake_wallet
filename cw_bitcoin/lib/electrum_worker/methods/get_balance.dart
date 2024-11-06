part of 'methods.dart';

class ElectrumWorkerGetBalanceRequest implements ElectrumWorkerRequest {
  ElectrumWorkerGetBalanceRequest({required this.scripthashes, this.id});

  final Set<String> scripthashes;
  final int? id;

  @override
  final String method = ElectrumRequestMethods.getBalance.method;

  @override
  factory ElectrumWorkerGetBalanceRequest.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetBalanceRequest(
      scripthashes: (json['scripthashes'] as List<String>).toSet(),
      id: json['id'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'method': method, 'scripthashes': scripthashes.toList()};
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

class ElectrumWorkerGetBalanceResponse
    extends ElectrumWorkerResponse<ElectrumBalance, Map<String, int>?> {
  ElectrumWorkerGetBalanceResponse({
    required super.result,
    super.error,
    super.id,
  }) : super(method: ElectrumRequestMethods.getBalance.method);

  @override
  Map<String, int>? resultJson(result) {
    return {"confirmed": result.confirmed, "unconfirmed": result.unconfirmed};
  }

  @override
  factory ElectrumWorkerGetBalanceResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerGetBalanceResponse(
      result: ElectrumBalance(
        confirmed: json['result']['confirmed'] as int,
        unconfirmed: json['result']['unconfirmed'] as int,
        frozen: 0,
      ),
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}
