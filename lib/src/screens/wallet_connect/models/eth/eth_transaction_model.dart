class WCEthereumTransactionModel {
  final String from;
  final String to;
  final String value;
  final String? nonce;
  final String? gasPrice;
  final String? maxFeePerGas;
  final String? maxPriorityFeePerGas;
  final String? gas;
  final String? gasLimit;
  final String? data;

  WCEthereumTransactionModel({
    required this.from,
    required this.to,
    required this.value,
    this.nonce,
    this.gasPrice,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.gas,
    this.gasLimit,
    this.data,
  });

  factory WCEthereumTransactionModel.fromJson(Map<String, dynamic> json) {
    return WCEthereumTransactionModel(
      from: json['from'] as String,
      to: json['to'] as String,
      value: json['value'] as String,
      nonce: json['nonce'] as String?,
      gasPrice: json['gasPrice'] as String?,
      maxFeePerGas: json['maxFeePerGas'] as String?,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String?,
      gas: json['gas'] as String?,
      gasLimit: json['gasLimit'] as String?,
      data: json['data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'value': value,
      'nonce': nonce,
      'gasPrice': gasPrice,
      'maxFeePerGas': maxFeePerGas,
      'maxPriorityFeePerGas': maxPriorityFeePerGas,
      'gas': gas,
      'gasLimit': gasLimit,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'EthereumTransactionModel(from: $from, to: $to, nonce: $nonce, gasPrice: $gasPrice, maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas, gas: $gas, gasLimit: $gasLimit, value: $value, data: $data)';
  }
}
