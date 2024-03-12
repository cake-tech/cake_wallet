import 'package:blockchain_utils/hex/hex.dart';
import 'package:on_chain/on_chain.dart';

class TronTRC20TransactionModel extends TronTransactionModel {
  String? transactionId;

  String? tokenSymbol;

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
  BigInt? get amount => BigInt.parse(value ?? '0');

  @override
  int? get fee => 0;

  TronTRC20TransactionModel({
    this.transactionId,
    this.tokenSymbol,
    this.timestamp,
    this.from,
    this.to,
    this.value,
  });

  TronTRC20TransactionModel.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id'];
    tokenSymbol = json['token_info'] != null ? json['token_info']['symbol'] : null;
    timestamp = json['block_timestamp'];
    from = json['from'];
    to = json['to'];
    value = json['value'];
  }
}

class TronTransactionModel {
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

  TronTransactionModel({
    this.ret,
    this.txID,
    this.blockTimestamp,
    this.contracts,
  });

  TronTransactionModel.fromJson(Map<String, dynamic> json) {
    if (json['ret'] != null) {
      ret = <Ret>[];
      json['ret'].forEach((v) {
        ret!.add(Ret.fromJson(v));
      });
    }
    txID = json['txID'];
    blockTimestamp = json['block_timestamp'];
    contracts = json['raw_data'] != null
        ? (json['raw_data']['contract'] as List)
            .map((e) => Contract.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;
  }
}

class Ret {
  String? contractRet;
  int? fee;

  Ret({this.contractRet, this.fee});

  Ret.fromJson(Map<String, dynamic> json) {
    contractRet = json['contractRet'];
    fee = json['fee'];
  }
}

class Contract {
  Parameter? parameter;
  String? type;

  Contract({this.parameter, this.type});

  Contract.fromJson(Map<String, dynamic> json) {
    parameter = json['parameter'] != null ? Parameter.fromJson(json['parameter']) : null;
    type = json['type'];
  }
}

class Parameter {
  Value? value;
  String? typeUrl;

  Parameter({this.value, this.typeUrl});

  Parameter.fromJson(Map<String, dynamic> json) {
    value = json['value'] != null ? Value.fromJson(json['value']) : null;
    typeUrl = json['type_url'];
  }
}

class Value {
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

  Value(
      {this.data,
      this.ownerAddress,
      this.contractAddress,
      this.amount,
      this.toAddress,
      this.assetName});

  Value.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    ownerAddress = json['owner_address'];
    contractAddress = json['contract_address'];
    amount = json['amount'];
    toAddress = json['to_address'];
    assetName = json['asset_name'];
  }

  /// To get the address from the encoded data field
  String _decodeAddressFromEncodedDataField(String output) {
    // To get the receiver address from the encoded params
    output = output.replaceFirst('0x', '').substring(8);
    final abiCoder = ABICoder.fromType('address');
    final decoded = abiCoder.decode(AbiParameter.bytes, hex.decode(output));
    final tronAddress = TronAddress.fromEthAddress((decoded.result as ETHAddress).toBytes());

    return tronAddress.toString();
  }

  /// To get the amount from the encoded data field
  BigInt _decodeAmountInvolvedFromEncodedDataField(String output) {
    output = output.replaceFirst('0x', '').substring(72);
    final amountAbiCoder = ABICoder.fromType('uint256');
    final decodedA = amountAbiCoder.decode(AbiParameter.uint256, hex.decode(output));
    final amount = decodedA.result as BigInt;

    return amount;
  }
}
