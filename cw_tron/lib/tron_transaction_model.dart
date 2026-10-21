import 'package:blockchain_utils/hex/hex.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:on_chain/on_chain.dart';

class TronTRC20TransactionModel extends TronTransactionModel {
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
    decimals = json['token_info'] != null ? json['token_info']['decimals'] : null;
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

  bool get isTrc20TransferCall => contracts?.first.parameter?.value?.isTrc20TransferCall ?? false;

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
  int? callValue;
  String? toAddress;
  String? assetName;

  /// Function selector of TRC20 `transfer(address,uint256)`.
  static const _transferSelector = "a9059cbb";

  /// Hex length of `transfer` calldata: the selector plus two 32-byte arguments.
  static const _transferCallDataLength = 8 + 64 + 64;

  String? get _callData {
    final callData = data?.toLowerCase();
    if (callData != null && callData.startsWith("0x")) {
      return callData.substring(2);
    }

    return callData;
  }

  /// Only a TRC20 `transfer` carries a receiver and a token amount in its calldata.
  /// Any other contract call (approve, swaps, deposit(), claim(), ...) has a different layout.
  bool get isTrc20TransferCall {
    final callData = _callData;

    return contractAddress != null &&
        callData != null &&
        callData.length >= _transferCallDataLength &&
        callData.startsWith(_transferSelector);
  }

  //Getters to extract address for tron transactions
  /// If the contract address is null, it returns the toAddress
  /// For a TRC20 transfer, it decodes the data field and gets the receiver address.
  /// For any other contract call, it returns the called contract.
  String? get receiverAddress {
    if (contractAddress == null) return toAddress;

    if (!isTrc20TransferCall) return contractAddress;

    return _decodeAddressFromEncodedDataField(_callData!);
  }

  //Getters to extract amount for tron transactions
  /// If the contract address is null, it returns the amount
  /// For a TRC20 transfer, it decodes the data field and gets the token amount.
  /// For any other contract call, it returns the TRX sent along with the call.
  BigInt? get txAmount {
    if (contractAddress == null) return BigInt.from(amount ?? 0);

    if (!isTrc20TransferCall) return BigInt.from(callValue ?? 0);

    return _decodeAmountInvolvedFromEncodedDataField(_callData!);
  }

  Value(
      {this.data,
      this.ownerAddress,
      this.contractAddress,
      this.amount,
      this.callValue,
      this.toAddress,
      this.assetName});

  Value.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    ownerAddress = json['owner_address'];
    contractAddress = json['contract_address'];
    amount = json['amount'];
    callValue = int.tryParse(json['call_value']?.toString() ?? "");
    toAddress = json['to_address'];
    assetName = json['asset_name'];
  }

  /// To get the address from the encoded data field
  String _decodeAddressFromEncodedDataField(String output) {
    // To get the receiver address from the encoded params
    output = output.substring(8);
    final abiCoder = ABICoder.fromType('address');
    final decoded = abiCoder.decode(AbiParameter.bytes, hex.decode(output));
    final tronAddress = TronAddress.fromEthAddress((decoded.result as ETHAddress).toBytes());

    return tronAddress.toString();
  }

  /// To get the amount from the encoded data field.
  /// Parsed directly, as on_chain's uint256 decoder rejects any value of 2^255 or more.
  BigInt _decodeAmountInvolvedFromEncodedDataField(String output) =>
      BigInt.parse(output.substring(72, _transferCallDataLength), radix: 16);
}
