import 'dart:convert';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_ethereum/deuro/constants.dart';
import 'package:cw_ethereum/deuro/deuro_base.dart';
import 'package:cw_ethereum/deuro/deuro_lending_contract.dart';
import 'package:cw_evm/contract/erc20.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DEuroLending extends DEuroBase {
  final MintingHubGateway _mintingGateway;

  DEuroLending(super.wallet_) : _mintingGateway = _getMintingGateway(wallet_.getWeb3Client()!);

  static MintingHubGateway _getMintingGateway(Web3Client client) => MintingHubGateway(
        address: EthereumAddress.fromHex(mintingGatewayAddress),
        client: client,
      );

  static const String _positionsEndpoint = 'https://api.deuro.com/positions/owners';

  Future<BigInt> getApprovedBalance(String tokenAddress) =>
      ERC20(address: EthereumAddress.fromHex(tokenAddress), client: wallet.getWeb3Client()!)
          .allowance(walletAddress, _mintingGateway.self.address);

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
      final fee = await wallet.calculateActualEstimatedFeeForCreateTransaction(
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
      final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);

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
        credentials: wallet.evmChainPrivateKey,
      );

      final sendTransaction = () => wallet.getWeb3Client()!.sendRawTransaction(signedTransaction);

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
      final ethBalance = await wallet.getWeb3Client()!.getBalance(walletAddress);
        throw InsufficientGasFeeException(currentBalance: ethBalance.getInWei);
      }
      rethrow;
    }
  }
}
