import 'dart:convert';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_ethereum/deuro/constants.dart';
import 'package:cw_ethereum/deuro/deuro_lending_contract.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DEuroLending {
  final MintingHubGateway _mintingGateway;
  final ERC20 _dEuro;
  final EthereumWallet _wallet;

  DEuroLending(EthereumWallet wallet)
      : _wallet = wallet,
        _mintingGateway = _getMintingGateway(wallet.getWeb3Client()!),
        _dEuro = _getDEuroToken(wallet.getWeb3Client()!);

  static const String _positionsEndpoint = 'https://api.deuro.com/positions/owners';

  static MintingHubGateway _getMintingGateway(Web3Client client) => MintingHubGateway(
        address: EthereumAddress.fromHex(mintingGatewayAddress),
        client: client,
      );

  static ERC20 _getDEuroToken(Web3Client client) => ERC20(
        address: EthereumAddress.fromHex(dEuroAddress),
        client: client,
      );

  EthereumAddress get _address => EthereumAddress.fromHex(_wallet.walletAddresses.primaryAddress);

  Future<BigInt> getApprovedBalance(String tokenAddress) =>
      ERC20(address: EthereumAddress.fromHex(tokenAddress), client: _wallet.getWeb3Client()!)
          .allowance(_address, _mintingGateway.self.address);

  Future<List<Map<String, dynamic>>> getPositionsOfAddress(String address) async {
    final result = await ProxyWrapper().get(clearnetUri: Uri.parse(_positionsEndpoint));

    if (result.statusCode != 200) throw Exception("Unable to load dEuro Positions");
    final data = jsonDecode(result.body) as Map<String, dynamic>;

    if ((data["owners"] as List).contains(address.toLowerCase())) {
      return (data["map"][address.toLowerCase()] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    return [];
  }

  Future<PendingEVMChainTransaction> clonePosition(
      int expiration,
      String parentPosition,
      BigInt initialCollateralAmount,
      BigInt initialMintAmount,
      EVMChainTransactionPriority priority) async {
    try {
      final fee = await _wallet.calculateActualEstimatedFeeForCreateTransaction(
        amount: BigInt.zero,
        contractAddress: _mintingGateway.self.address.hexEip55,
        receivingAddressHex: _mintingGateway.self.address.hexEip55,
        priority: priority,
        data: _mintingGateway.self.abi.functions[13].encodeCall([
          EthereumAddress.fromHex(parentPosition),
          initialCollateralAmount,
          initialMintAmount,
          BigInt.from(expiration),
          hexToBytes(frontendCode),
        ]),
      );
      final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);

      final estimatedGasFee = BigInt.from(fee.estimatedGasFee);

      if (ethBalance.getInWei < estimatedGasFee) {
        throw InsufficientGasFeeException(
            requiredGasFee: estimatedGasFee, currentBalance: ethBalance.getInWei);
      }

      final signedTransaction = await _mintingGateway.clone(
        (
          expiration: BigInt.from(expiration),
          initialCollateral: initialCollateralAmount,
          initialMint: initialMintAmount,
          parent: EthereumAddress.fromHex(parentPosition),
          frontendCode: hexToBytes(frontendCode)
        ),
        credentials: _wallet.evmChainPrivateKey,
      );

      final sendTransaction = () => _wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

      return PendingEVMChainTransaction(
        feeCurrency: "ETH",
        sendTransaction: sendTransaction,
        signedTransaction: signedTransaction,
        fee: BigInt.from(fee.estimatedGasFee),
        amount: initialMintAmount.toString(),
        exponent: 18,
      );
    } catch (e) {
      if (e.toString().contains('insufficient funds for gas')) {
        final ethBalance = await _wallet.getWeb3Client()!.getBalance(_address);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }
}
