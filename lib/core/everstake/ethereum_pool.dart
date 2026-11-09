import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/web3dart.dart";

typedef EverstakeEthereumCall = ({String to, String data, Money value});

class EverstakeEthereumPool {
  EverstakeEthereumPool(this._ethCall);

  // Mainnet contracts and gas reserve from @everstake/wallet-sdk-ethereum 1.1.4.
  static const gasReserve = 220000;
  static const _poolAddress = "0xD523794C879D9eC028960a231F866758e405bE34";
  static const _accountingAddress = "0x7a7f0b3c23C23a31cFcb0c44709be70d4D545c6e";

  static final _pool = _contract(_poolAddress, "EverstakePool", '''
    [
      {
        "type": "function",
        "name": "stake",
        "stateMutability": "payable",
        "inputs": [{"name": "source", "type": "uint64"}]
      },
      {
        "type": "function",
        "name": "unstake",
        "inputs": [
          {"name": "value", "type": "uint256"},
          {"name": "allowedInterchangeNum", "type": "uint16"},
          {"name": "source", "type": "uint64"}
        ],
        "outputs": [{"name": "", "type": "uint256"}]
      },
      {
        "type": "function",
        "name": "unstakePending",
        "inputs": [{"name": "amount", "type": "uint256"}]
      }
    ]
  ''');

  static final _accounting = _contract(_accountingAddress, "EverstakeAccounting", '''
    [{"type": "function", "name": "claimWithdrawRequest", "inputs": []}]
  ''');

  // TODO(lapatric): add Cake Wallet's Everstake source once it is available
  static final _source = BigInt.zero;
  static final _allowedInterchangeNum = BigInt.from(5);

  final Future<String> Function(EverstakeEthereumCall call) _ethCall;

  EverstakeEthereumCall stakeCall(Money amount) =>
      _buildCall(_pool, "stake", [_source], value: _requireEth(amount));

  EverstakeEthereumCall unstakeCall(Money amount) =>
      _buildCall(_pool, "unstake", [_requireEth(amount).amount, _allowedInterchangeNum, _source]);

  EverstakeEthereumCall unstakePendingCall(Money amount) =>
      _buildCall(_pool, "unstakePending", [_requireEth(amount).amount]);

  EverstakeEthereumCall claimWithdrawRequestCall() =>
      _buildCall(_accounting, "claimWithdrawRequest", const []);

  Future<String> dryRun(EverstakeEthereumCall call) => _ethCall(call);

  // An unstake returns the part paid out at once; the rest joins the withdrawal queue.
  Money instantUnstakeAmount(String unstakeResult) {
    final instant = _pool.function("unstake").decodeReturnValues(unstakeResult).single as BigInt;
    return Money(instant, CryptoCurrency.eth);
  }

  EverstakeEthereumCall _buildCall(
    DeployedContract contract,
    String function,
    List<dynamic> arguments, {
    Money? value,
  }) =>
      (
        to: contract.address.hex,
        data: bytesToHex(contract.function(function).encodeCall(arguments), include0x: true),
        value: value ?? Money.zero(CryptoCurrency.eth),
      );

  Money _requireEth(Money amount) {
    if (amount.currency != CryptoCurrency.eth || amount.decimals != CryptoCurrency.eth.decimals) {
      throw ArgumentError.value(amount, "amount", "Expected ETH with 18 decimals");
    }
    if (amount.amount.isNegative || amount.amount.bitLength > 256) {
      throw ArgumentError.value(amount, "amount", "Expected a uint256");
    }
    return amount;
  }

  static DeployedContract _contract(String address, String name, String abiJson) =>
      DeployedContract(ContractAbi.fromJson(abiJson, name), EthereumAddress.fromHex(address));
}
