import "dart:typed_data";

import "package:hex/hex.dart" as hex;
import "package:web3dart/web3dart.dart" as web3;

// Minimal ABI, per developers.circle.com/cctp/references/contract-interfaces.
const String _tokenMessengerV2AbiJson = """
[
  {
    "inputs": [
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "uint32", "name": "destinationDomain", "type": "uint32"},
      {"internalType": "bytes32", "name": "mintRecipient", "type": "bytes32"},
      {"internalType": "address", "name": "burnToken", "type": "address"},
      {"internalType": "bytes32", "name": "destinationCaller", "type": "bytes32"},
      {"internalType": "uint256", "name": "maxFee", "type": "uint256"},
      {"internalType": "uint32", "name": "minFinalityThreshold", "type": "uint32"},
      {"internalType": "bytes", "name": "hookData", "type": "bytes"}
    ],
    "name": "depositForBurnWithHook",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
""";

final web3.ContractAbi tokenMessengerV2ContractAbi =
    web3.ContractAbi.fromJson(_tokenMessengerV2AbiJson, "TokenMessengerV2");

String encodeDepositForBurnWithHook({
  required BigInt amount,
  required int destinationDomain,
  required List<int> mintRecipient,
  required String burnToken,
  required List<int> destinationCaller,
  required BigInt maxFee,
  required int minFinalityThreshold,
  required List<int> hookData,
}) {
  final fn = tokenMessengerV2ContractAbi.functions.single;
  final encoded = fn.encodeCall([
    amount,
    BigInt.from(destinationDomain),
    Uint8List.fromList(mintRecipient),
    web3.EthereumAddress.fromHex(burnToken),
    Uint8List.fromList(destinationCaller),
    maxFee,
    BigInt.from(minFinalityThreshold),
    Uint8List.fromList(hookData),
  ]);
  return "0x${hex.HEX.encode(encoded)}";
}
