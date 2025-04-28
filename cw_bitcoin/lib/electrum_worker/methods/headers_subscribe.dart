part of 'methods.dart';

class ElectrumWorkerHeadersSubscribeRequest implements ElectrumWorkerRequest {
  ElectrumWorkerHeadersSubscribeRequest({
    required this.transactions,
    required this.walletType,
    this.id,
    this.completed = false,
  });

  @override
  final String method = ElectrumRequestMethods.headersSubscribe.method;
  final int? id;
  final bool completed;

  final Map<String, ElectrumTransactionInfo> transactions;
  final WalletType walletType;

  @override
  factory ElectrumWorkerHeadersSubscribeRequest.fromJson(Map<String, dynamic> json) {
    final walletType = deserializeFromInt(json['walletType'] as int);
    return ElectrumWorkerHeadersSubscribeRequest(
      transactions: (json['transactions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ElectrumTransactionInfo.fromJson(value as Map<String, dynamic>, walletType),
        ),
      ),
      walletType: walletType,
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
      'transactions': transactions.map((key, value) => MapEntry(key, value.toJson())),
      'walletType': serializeToInt(walletType),
    };
  }
}

class ElectrumWorkerHeadersSubscribeError extends ElectrumWorkerErrorResponse {
  ElectrumWorkerHeadersSubscribeError({
    required super.error,
    super.id,
  }) : super();

  @override
  final String method = ElectrumRequestMethods.headersSubscribe.method;
}

class ElectrumWorkerHeadersResponse {
  ElectrumWorkerHeadersResponse({
    required this.headerResponse,
    required this.transactions,
    required this.walletType,
    required this.anyTxWasUpdated,
  });

  final ElectrumHeaderResponse headerResponse;
  final Map<String, ElectrumTransactionInfo> transactions;
  final WalletType walletType;
  final bool anyTxWasUpdated;

  static ElectrumWorkerHeadersResponse fromJson(Map<String, dynamic> json) {
    final walletType = deserializeFromInt(json['walletType'] as int);
    return ElectrumWorkerHeadersResponse(
      headerResponse:
          ElectrumHeaderResponse.fromJson(json['headerResponse'] as Map<String, dynamic>),
      transactions: (json['transactions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ElectrumTransactionInfo.fromJson(value as Map<String, dynamic>, walletType),
        ),
      ),
      walletType: walletType,
      anyTxWasUpdated: json['anyTxWasUpdated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerResponse': headerResponse.toJson(),
      'transactions': transactions.map((key, value) => MapEntry(key, value.toJson())),
      'walletType': serializeToInt(walletType),
      'anyTxWasUpdated': anyTxWasUpdated,
    };
  }
}

class ElectrumWorkerHeadersSubscribeResponse
    extends ElectrumWorkerResponse<ElectrumWorkerHeadersResponse, Map<String, dynamic>> {
  ElectrumWorkerHeadersSubscribeResponse({
    required super.result,
    super.error,
    super.id,
    super.completed,
  }) : super(method: ElectrumRequestMethods.headersSubscribe.method);

  @override
  Map<String, dynamic> resultJson(result) {
    return result.toJson();
  }

  @override
  factory ElectrumWorkerHeadersSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumWorkerHeadersSubscribeResponse(
      result: ElectrumWorkerHeadersResponse.fromJson(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
      id: json['id'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
