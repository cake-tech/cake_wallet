import 'dart:typed_data';

import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:web3dart/web3dart.dart';

class EthereumClient extends EVMChainClient {
  EthereumClient() : super(chainId: 1);

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) =>
      prependTransactionType(0x02, signedTransaction);
}

