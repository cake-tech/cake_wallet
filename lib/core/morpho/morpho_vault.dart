import "dart:typed_data";

import "package:cw_core/amount/money.dart";
import "package:cw_core/erc20_token.dart";
import "package:web3dart/crypto.dart";
import "package:web3dart/web3dart.dart";

typedef EthCall = Future<String> Function(String to, String data);
typedef ContractCall = ({String to, String data});

class MorphoVault {
  MorphoVault(this._ethCall);

  static const chainId = 1;
  static const _usdcDecimals = 6;
  // lowercase: Erc20Token equality is case-sensitive
  static const _usdcAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  static const vaultAddress = "0xbeef088055857739C12CD3765F20b7679Def0f51";
  static const _morphoBlueAddress = "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb";
  static const _supportedLiquidityAdapterAddress = "0x2b9681015A1FA2225D1FC8ae40538d3D64C58290";

  static final usdcToken = Erc20Token(
    name: "USD Coin",
    symbol: "USDC",
    contractAddress: _usdcAddress,
    decimal: _usdcDecimals,
    tag: "ETH",
  );

  static final _usdc = _contract(_usdcAddress, "ERC20", '''
    [
      {
        "type": "function",
        "name": "approve",
        "inputs": [{"name": "spender", "type": "address"}, {"name": "amount", "type": "uint256"}]
      },
      {
        "type": "function",
        "name": "allowance",
        "stateMutability": "view",
        "inputs": [{"name": "owner", "type": "address"}, {"name": "spender", "type": "address"}],
        "outputs": [{"name": "", "type": "uint256"}]
      },
      {
        "type": "function",
        "name": "balanceOf",
        "stateMutability": "view",
        "inputs": [{"name": "account", "type": "address"}],
        "outputs": [{"name": "", "type": "uint256"}]
      }
    ]
  ''');

  static final _vault = _contract(vaultAddress, "MorphoVaultV2", '''
    [
      {
        "type": "function",
        "name": "deposit",
        "inputs": [{"name": "assets", "type": "uint256"}, {"name": "onBehalf", "type": "address"}]
      },
      {
        "type": "function",
        "name": "withdraw",
        "inputs": [
          {"name": "assets", "type": "uint256"},
          {"name": "receiver", "type": "address"},
          {"name": "onBehalf", "type": "address"}
        ]
      },
      {
        "type": "function",
        "name": "redeem",
        "inputs": [
          {"name": "shares", "type": "uint256"},
          {"name": "receiver", "type": "address"},
          {"name": "onBehalf", "type": "address"}
        ]
      },
      {
        "type": "function",
        "name": "balanceOf",
        "stateMutability": "view",
        "inputs": [{"name": "account", "type": "address"}],
        "outputs": [{"name": "", "type": "uint256"}]
      },
      {
        "type": "function",
        "name": "previewRedeem",
        "stateMutability": "view",
        "inputs": [{"name": "shares", "type": "uint256"}],
        "outputs": [{"name": "", "type": "uint256"}]
      },
      {
        "type": "function",
        "name": "liquidityAdapter",
        "stateMutability": "view",
        "inputs": [],
        "outputs": [{"name": "", "type": "address"}]
      },
      {
        "type": "function",
        "name": "liquidityData",
        "stateMutability": "view",
        "inputs": [],
        "outputs": [{"name": "", "type": "bytes"}]
      }
    ]
  ''');

  static final _morphoBlue = _contract(_morphoBlueAddress, "MorphoBlue", '''
    [
      {
        "type": "function",
        "name": "market",
        "stateMutability": "view",
        "inputs": [{"name": "id", "type": "bytes32"}],
        "outputs": [
          {"name": "totalSupplyAssets", "type": "uint128"},
          {"name": "totalSupplyShares", "type": "uint128"},
          {"name": "totalBorrowAssets", "type": "uint128"},
          {"name": "totalBorrowShares", "type": "uint128"},
          {"name": "lastUpdate", "type": "uint128"},
          {"name": "fee", "type": "uint128"}
        ]
      }
    ]
  ''');

  static final _supportedLiquidityAdapter =
      _contract(_supportedLiquidityAdapterAddress, "MorphoMarketV1AdapterV2", '''
    [
      {
        "type": "function",
        "name": "expectedSupplyAssets",
        "stateMutability": "view",
        "inputs": [{"name": "marketId", "type": "bytes32"}],
        "outputs": [{"name": "", "type": "uint256"}]
      }
    ]
  ''');

  static final _zeroAddress = EthereumAddress.fromHex("0x0000000000000000000000000000000000000000");

  final EthCall _ethCall;

  ContractCall usdcApproveCall(Money assets) =>
      _buildCall(_usdc, "approve", [_vault.address, _requireUsdc(assets)]);

  ContractCall depositCall(Money assets, String owner) =>
      _buildCall(_vault, "deposit", [_requireUsdc(assets), EthereumAddress.fromHex(owner)]);

  ContractCall withdrawCall(Money assets, String owner) {
    final user = EthereumAddress.fromHex(owner);
    return _buildCall(_vault, "withdraw", [_requireUsdc(assets), user, user]);
  }

  ContractCall redeemCall(BigInt shares, String owner) {
    final user = EthereumAddress.fromHex(owner);
    return _buildCall(_vault, "redeem", [_requireUint256(shares), user, user]);
  }

  Future<void> dryRun(ContractCall call) => _ethCall(call.to, call.data);

  Future<Money> getUsdcBalance(String owner) async => Money(
        await _querySingle<BigInt>(_usdc, "balanceOf", [EthereumAddress.fromHex(owner)]),
        usdcToken,
      );

  Future<Money> getUsdcAllowance(String owner) async => Money(
        await _querySingle<BigInt>(
          _usdc,
          "allowance",
          [EthereumAddress.fromHex(owner), _vault.address],
        ),
        usdcToken,
      );

  Future<BigInt> getShareBalance(String owner) =>
      _querySingle<BigInt>(_vault, "balanceOf", [EthereumAddress.fromHex(owner)]);

  Future<Money> previewRedeem(BigInt shares) async => Money(
        await _querySingle<BigInt>(_vault, "previewRedeem", [_requireUint256(shares)]),
        usdcToken,
      );

  Future<Money?> getAvailableLiquidity() async {
    final (idleUsdc, liquidityAdapterAddress, liquidityData) = await (
      _querySingle<BigInt>(_usdc, "balanceOf", [_vault.address]),
      _querySingle<EthereumAddress>(_vault, "liquidityAdapter", const []),
      _querySingle<Uint8List>(_vault, "liquidityData", const []),
    ).wait;
    if (liquidityAdapterAddress == _zeroAddress) {
      return Money(idleUsdc, usdcToken);
    }
    if (liquidityAdapterAddress != _supportedLiquidityAdapter.address) {
      return null;
    }
    final liquidityMarketId = keccak256(liquidityData);
    final (
      vaultSupplyInMarket,
      [totalSupplyAssets as BigInt, _, totalBorrowAssets as BigInt, ...],
    ) = await (
      _querySingle<BigInt>(_supportedLiquidityAdapter, "expectedSupplyAssets", [liquidityMarketId]),
      _query(_morphoBlue, "market", [liquidityMarketId]),
    ).wait;
    final freeLiquidity = totalSupplyAssets - totalBorrowAssets;
    final withdrawableFromMarket =
        vaultSupplyInMarket < freeLiquidity ? vaultSupplyInMarket : freeLiquidity;
    return Money(idleUsdc + withdrawableFromMarket, usdcToken);
  }

  Future<List<dynamic>> _query(
    DeployedContract contract,
    String function,
    List<dynamic> arguments,
  ) async {
    final call = _buildCall(contract, function, arguments);
    final result = await _ethCall(call.to, call.data);
    return contract.function(function).decodeReturnValues(result);
  }

  Future<T> _querySingle<T>(
    DeployedContract contract,
    String function,
    List<dynamic> arguments,
  ) async =>
      (await _query(contract, function, arguments)).single as T;

  ContractCall _buildCall(DeployedContract contract, String function, List<dynamic> arguments) => (
        to: contract.address.hex,
        data: bytesToHex(contract.function(function).encodeCall(arguments), include0x: true),
      );

  BigInt _requireUsdc(Money assets) {
    if (usdcToken != assets.currency || assets.decimals != _usdcDecimals) {
      throw ArgumentError.value(assets, "assets", "Expected Ethereum USDC");
    }
    return _requireUint256(assets.amount);
  }

  static BigInt _requireUint256(BigInt value) {
    if (value.isNegative || value.bitLength > 256) {
      throw ArgumentError("Expected a uint256, got $value");
    }
    return value;
  }

  static DeployedContract _contract(String address, String name, String abiJson) =>
      DeployedContract(ContractAbi.fromJson(abiJson, name), EthereumAddress.fromHex(address));
}
