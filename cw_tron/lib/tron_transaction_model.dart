import "package:blockchain_utils/hex/hex.dart";
import "package:cw_core/crypto_currency.dart";
import "package:on_chain/on_chain.dart";

class TronTRC20TransactionModel extends TronTransactionModel {
  TronTRC20TransactionModel({
    this.transactionId,
    this.tokenSymbol,
    this.timestamp,
    this.from,
    this.to,
    this.value,
  });

  TronTRC20TransactionModel.fromJson(Map<String, dynamic> json) {
    final tokenInfo = json["token_info"] as Map<String, dynamic>?;
    transactionId = json["transaction_id"] as String?;
    tokenSymbol = tokenInfo?["symbol"] as String?;
    decimals = tokenInfo?["decimals"] as int?;
    timestamp = json["block_timestamp"] as int?;
    from = json["from"] as String?;
    to = json["to"] as String?;
    value = json["value"] as String?;
  }

  TronTRC20TransactionModel.fromTronScanJson(Map<String, dynamic> json) {
    final tokenInfo = json["tokenInfo"] as Map<String, dynamic>?;
    transactionId = json["transaction_id"] as String?;
    tokenSymbol = tokenInfo?["tokenAbbr"] as String?;
    decimals = tokenInfo?["tokenDecimal"] as int?;
    timestamp = json["block_ts"] as int?;
    from = json["from_address"] as String?;
    to = json["to_address"] as String?;
    value = json["quant"] as String?;
  }
  String? transactionId;

  String? tokenSymbol;

  int? decimals;

  CryptoCurrency get currency => CryptoCurrency(
      name: tokenSymbol ?? "TRX", title: tokenSymbol ?? "TRX", decimals: decimals ?? 6);

  int? timestamp;

  @override
  String? from;

  @override
  String? to;

  String? value;

  @override
  String get hash => transactionId!;

  @override
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp ?? 0);

  @override
  BigInt? get amount => BigInt.parse(value ?? "0");

  @override
  int? get fee => 0;
}

class TronTransactionModel {
  TronTransactionModel({
    this.ret,
    this.txID,
    this.blockTimestamp,
    this.contracts,
  });

  TronTransactionModel.fromTronScanJson(Map<String, dynamic> json) {
    txID = json["hash"] as String?;
    blockTimestamp = json["timestamp"] as int?;
    final cost = json["cost"] as Map<String, dynamic>?;
    ret = [
      Ret(
        contractRet: json["contractRet"] as String?,
        fee: cost?["fee"] as int?,
      ),
    ];
    contracts = [
      Contract(
        type: TransactionContractType.findByValue(json["contractType"] as int)?.name,
        parameter: Parameter(
          value: Value.fromTronScanJson(json["contractData"] as Map<String, dynamic>),
        ),
      ),
    ];
  }

  TronTransactionModel.fromJson(Map<String, dynamic> json) {
    txID = json["txID"] as String?;
    blockTimestamp = json["block_timestamp"] as int?;
    if (json["ret"] != null) {
      ret = (json["ret"] as List<dynamic>)
          .map((v) => Ret.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    contracts = json["raw_data"] != null
        ? ((json["raw_data"] as Map<String, dynamic>)["contract"] as List<dynamic>)
            .map((e) => Contract.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;
  }
  List<Ret>? ret;
  String? txID;
  int? blockTimestamp;
  List<Contract>? contracts;

  /// Getters to extract out the needed/useful information directly from the model params
  /// Without having to go through extra steps in the methods that use this model.
  bool get isError {
    if (ret?.first.contractRet == null) return true;

    return ret?.first.contractRet != "SUCCESS";
  }

  String get hash => txID!;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(blockTimestamp ?? 0);

  String? get from => contracts?.first.parameter?.value?.ownerAddress;

  String? get to => contracts?.first.parameter?.value?.receiverAddress;

  BigInt? get amount => contracts?.first.parameter?.value?.txAmount;

  int? get fee => ret?.first.fee;

  String? get contractAddress => contracts?.first.parameter?.value?.contractAddress;

  bool get isTrc20Transfer {
    final data = contracts?.first.parameter?.value?.data?.toLowerCase().replaceFirst("0x", "");

    return data != null && data.length >= 136 && data.startsWith("a9059cbb");
  }
}

class Ret {
  Ret({this.contractRet, this.fee});

  Ret.fromJson(Map<String, dynamic> json) {
    contractRet = json["contractRet"] as String?;
    fee = json["fee"] as int?;
  }
  String? contractRet;
  int? fee;
}

class Contract {
  Contract({this.parameter, this.type});

  Contract.fromJson(Map<String, dynamic> json) {
    parameter = json["parameter"] != null
        ? Parameter.fromJson(json["parameter"] as Map<String, dynamic>)
        : null;
    type = json["type"] as String?;
  }
  Parameter? parameter;
  String? type;
}

class Parameter {
  Parameter({this.value, this.typeUrl});

  Parameter.fromJson(Map<String, dynamic> json) {
    value = json["value"] != null ? Value.fromJson(json["value"] as Map<String, dynamic>) : null;
    typeUrl = json["type_url"] as String?;
  }
  Value? value;
  String? typeUrl;
}

class Value {
  Value({
    this.data,
    this.ownerAddress,
    this.contractAddress,
    this.amount,
    this.toAddress,
    this.assetName,
  });

  Value.fromJson(Map<String, dynamic> json) {
    data = json["data"] as String?;
    ownerAddress = json["owner_address"] as String?;
    contractAddress = json["contract_address"] as String?;
    amount = json["amount"] as int?;
    toAddress = json["to_address"] as String?;
    assetName = json["asset_name"] as String?;
  }

  Value.fromTronScanJson(Map<String, dynamic> json) {
    data = json["data"] as String?;
    ownerAddress = _toHexAddress(json["owner_address"] as String?);
    contractAddress = _toHexAddress(json["contract_address"] as String?);
    amount = json["amount"] as int?;
    toAddress = _toHexAddress(json["to_address"] as String?);
    assetName = json["asset_name"] as String?;
  }
  String? data;
  String? ownerAddress;
  String? contractAddress;
  int? amount;
  String? toAddress;
  String? assetName;

  //Getters to extract address for tron transactions
  /// If the contract address is null, it returns the toAddress
  /// If it's not null, it decodes the data field and gets the receiver address.
  String? get receiverAddress {
    if (contractAddress == null) return toAddress;

    if (data == null) return null;

    return _decodeAddressFromEncodedDataField(data!);
  }

  //Getters to extract amount for tron transactions
  /// If the contract address is null, it returns the amount
  /// If it's not null, it decodes the data field and gets the tx amount.
  BigInt? get txAmount {
    if (contractAddress == null) return BigInt.from(amount ?? 0);

    if (data == null) return null;

    return _decodeAmountInvolvedFromEncodedDataField(data!);
  }

  static String? _toHexAddress(String? address) =>
      address == null ? null : TronAddress(address).toHex();

  /// To get the address from the encoded data field
  String _decodeAddressFromEncodedDataField(String output) {
    // To get the receiver address from the encoded params
    output = output.replaceFirst("0x", "").substring(8);
    final abiCoder = ABICoder.fromType("address");
    final decoded = abiCoder.decode(AbiParameter.bytes, hex.decode(output));
    final tronAddress = TronAddress.fromEthAddress((decoded.result as ETHAddress).toBytes());

    return tronAddress.toString();
  }

  /// To get the amount from the encoded data field
  BigInt _decodeAmountInvolvedFromEncodedDataField(String output) {
    output = output.replaceFirst("0x", "").substring(72);
    final amountAbiCoder = ABICoder.fromType("uint256");
    final decodedA = amountAbiCoder.decode(AbiParameter.uint256, hex.decode(output));
    final amount = decodedA.result as BigInt;

    return amount;
  }
}
