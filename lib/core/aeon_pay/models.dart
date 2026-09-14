import "package:cake_wallet/core/open_crypto_pay/models.dart";

class AeonPayRequest {
  AeonPayRequest({
    required this.receiverName,
    required this.expiry,
    required this.callbackUrl,
    required this.quote,
    required this.methods,
  });

  final String receiverName;
  final int expiry;
  final String callbackUrl;
  final String quote;
  final Map<String, List<OpenCryptoPayQuoteAsset>> methods;
}


class AeonPayDecodeQrDTO {
  AeonPayDecodeQrDTO({
    required this.code,
    required this.msg,
    required this.traceId,
    required this.error,
    required this.success,
    this.model,
  });

  AeonPayDecodeQrDTO.fromJson(Map<String, dynamic> json)
      : code = json["code"] as String,
        msg = json["msg"] as String,
        traceId = json["traceId"] as String,
        model = (json["model"] != null)
            ? AeonPayDecodeQrModel.fromJson(json["model"] as Map<String, dynamic>)
            : null,
        error = json["error"] as bool,
        success = json["success"] as bool;

  final String code;
  final String msg;
  final String traceId;
  final AeonPayDecodeQrModel? model;
  final bool error;
  final bool success;
}

class AeonPayDecodeQrModel {
  AeonPayDecodeQrModel({
    required this.bankCode,
    required this.bankName,
    required this.currency,
    this.bankAccountName,
    this.bankAccountNumber,
    this.amount,
  });

  AeonPayDecodeQrModel.fromJson(Map<String, dynamic> json)
      : bankAccountName = json["bankAccountName"] as String,
        bankAccountNumber = json["bankAccountNumber"] as String,
        bankCode = json["bankCode"] as String,
        bankName = json["bankName"] as String,
        currency = json["currency"] as String,
        amount = json["amount"] as double?;

  final String currency;
  final String bankCode;
  final String bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final double? amount;
}

class AeonPayCreateOrderDTO {
  AeonPayCreateOrderDTO({
    required this.code,
    required this.msg,
    required this.traceId,
    required this.error,
    required this.success,
    this.model,
  });

  AeonPayCreateOrderDTO.fromJson(Map<String, dynamic> json)
      : code = json["code"] as String,
        msg = json["msg"] as String,
        traceId = json["traceId"] as String,
        model = (json["model"] != null)
            ? AeonPayCreateOrderModel.fromJson(json["model"] as Map<String, dynamic>)
            : null,
        error = json["error"] as bool,
        success = json["success"] as bool;

  final String code;
  final String msg;
  final String traceId;
  final bool error;
  final bool success;
  final AeonPayCreateOrderModel? model;
}

class AeonPayCreateOrderModel {
  AeonPayCreateOrderModel({required this.amount, required this.orderNo});

  AeonPayCreateOrderModel.fromJson(Map<String, dynamic> json)
      : amount = json["amount"] as String,
        orderNo = json["orderNo"] as String;

  final String amount;
  final String orderNo;
}
