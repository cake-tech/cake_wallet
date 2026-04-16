import 'dart:typed_data';

import 'package:cw_evm/usdt0/usdt0_quote.dart';
import 'package:hex/hex.dart' as hex;
import 'package:web3dart/web3dart.dart' as web3;

/// Minimal OFT ABI for USDT0 (per docs.usdt0.to).
/// quoteSend(SendParam, bool payInLzToken) returns MessagingFee.
/// send(SendParam, MessagingFee, address refundAddress) payable.
/// SendParam: dstEid, to (bytes32), amountLD (amount to send, token units),
///   minAmountLD (min receive on destination), extraOptions, composeMsg, oftCmd.
const String _oftAbiJson = '''
[
  {
    "inputs": [
      {
        "components": [
          {"internalType": "uint32", "name": "dstEid", "type": "uint32"},
          {"internalType": "bytes32", "name": "to", "type": "bytes32"},
          {"internalType": "uint256", "name": "amountLD", "type": "uint256"},
          {"internalType": "uint256", "name": "minAmountLD", "type": "uint256"},
          {"internalType": "bytes", "name": "extraOptions", "type": "bytes"},
          {"internalType": "bytes", "name": "composeMsg", "type": "bytes"},
          {"internalType": "bytes", "name": "oftCmd", "type": "bytes"}
        ],
        "internalType": "struct SendParam",
        "name": "sendParam",
        "type": "tuple"
      },
      {"internalType": "bool", "name": "payInLzToken", "type": "bool"}
    ],
    "name": "quoteSend",
    "outputs": [
      {
        "components": [
          {"internalType": "uint256", "name": "nativeFee", "type": "uint256"},
          {"internalType": "uint256", "name": "lzTokenFee", "type": "uint256"}
        ],
        "internalType": "struct MessagingFee",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "components": [
          {"internalType": "uint32", "name": "dstEid", "type": "uint32"},
          {"internalType": "bytes32", "name": "to", "type": "bytes32"},
          {"internalType": "uint256", "name": "amountLD", "type": "uint256"},
          {"internalType": "uint256", "name": "minAmountLD", "type": "uint256"},
          {"internalType": "bytes", "name": "extraOptions", "type": "bytes"},
          {"internalType": "bytes", "name": "composeMsg", "type": "bytes"},
          {"internalType": "bytes", "name": "oftCmd", "type": "bytes"}
        ],
        "internalType": "struct SendParam",
        "name": "_sendParam",
        "type": "tuple"
      },
      {
        "components": [
          {"internalType": "uint256", "name": "nativeFee", "type": "uint256"},
          {"internalType": "uint256", "name": "lzTokenFee", "type": "uint256"}
        ],
        "internalType": "struct MessagingFee",
        "name": "_fee",
        "type": "tuple"
      },
      {"internalType": "address", "name": "_refundAddress", "type": "address"}
    ],
    "name": "send",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }
]
''';

final web3.ContractAbi oftContractAbi = web3.ContractAbi.fromJson(_oftAbiJson, 'OFT');

/// OFT contract wrapper for quoteSend (view) and send (payable).
class OFT {
  OFT({
    required web3.EthereumAddress address,
    required web3.Web3Client client,
  })  : _address = address,
        _client = client;

  final web3.EthereumAddress _address;
  final web3.Web3Client _client;

  /// Calls quoteSend and returns MessagingFee (nativeFee, lzTokenFee).
  Future<USDT0Quote> quoteSend({
    required int dstEid,
    required List<int> toBytes32,
    required BigInt amountLD,
    required BigInt minAmountLD,
    Uint8List? extraOptions,
    Uint8List? composeMsg,
    Uint8List? oftCmd,
    bool payInLzToken = false,
  }) async {
    final contract = web3.DeployedContract(
      oftContractAbi,
      _address,
    );
    final fn = contract.function('quoteSend');
    final sendParam = [
      BigInt.from(dstEid),
      Uint8List.fromList(toBytes32),
      amountLD,
      minAmountLD,
      extraOptions ?? Uint8List(0),
      composeMsg ?? Uint8List(0),
      oftCmd ?? Uint8List(0),
    ];
    final params = [sendParam, payInLzToken];

    final result = await _client.call(
      contract: contract,
      function: fn,
      params: params,
    );

    final msgFee = result.first as List<dynamic>;
    final nativeFee = msgFee[0] as BigInt;
    final lzTokenFee = msgFee[1] as BigInt;
    return USDT0Quote(nativeFee: nativeFee, lzTokenFee: lzTokenFee);
  }

  /// Encodes send(SendParam, MessagingFee, refundAddress) for transaction.
  /// Returns (dataHex, valueWei) where valueWei is the native fee to send.
  ({String dataHex, BigInt valueWei}) encodeSend({
    required int dstEid,
    required List<int> toBytes32,
    required BigInt amountLD,
    required BigInt minAmountLD,
    required BigInt nativeFee,
    required BigInt lzTokenFee,
    required String refundAddress,
    Uint8List? extraOptions,
    Uint8List? composeMsg,
    Uint8List? oftCmd,
  }) {
    final contract = web3.DeployedContract(oftContractAbi, _address);
    final fn = contract.function('send');
    final sendParam = [
      BigInt.from(dstEid),
      Uint8List.fromList(toBytes32),
      amountLD,
      minAmountLD,
      extraOptions ?? Uint8List(0),
      composeMsg ?? Uint8List(0),
      oftCmd ?? Uint8List(0),
    ];
    final fee = [nativeFee, lzTokenFee];
    final refund = web3.EthereumAddress.fromHex(refundAddress);
    final encoded = fn.encodeCall([sendParam, fee, refund]);
    final dataHex = '0x${hex.HEX.encode(encoded)}';
    return (dataHex: dataHex, valueWei: nativeFee);
  }
}

/// Converts EVM address (0x + 40 hex) to bytes32 (left-padded).
List<int> addressToBytes32(String address) {
  final clean = address.startsWith('0x') ? address.substring(2) : address;

  if (clean.length != 40) throw ArgumentError('Invalid address length');

  return hex.HEX.decode('000000000000000000000000$clean');
}
