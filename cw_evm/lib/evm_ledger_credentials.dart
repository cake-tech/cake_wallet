import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/device_not_connected_exception.dart'
    as exception;
import 'package:cw_core/utils/print_verbose.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EvmLedgerCredentials extends CredentialsWithKnownAddress {
  final String _address;

  EthereumLedgerApp? ethereumLedgerApp;

  EvmLedgerCredentials(this._address);

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void setLedgerConnection(LedgerConnection connection,
      [String? derivationPath]) {
    ethereumLedgerApp = EthereumLedgerApp(connection,
        derivationPath: derivationPath ?? "m/44'/60'/0'/0/0");
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload,
          {int? chainId, bool isEIP1559 = false}) =>
      throw UnimplementedError("EvmLedgerCredentials.signToEcSignature");

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) async {
    if (ethereumLedgerApp == null) {
      throw exception.DeviceNotConnectedException();
    }

    final sig = await ethereumLedgerApp!.signTransaction(payload);

    final v = sig[0].toInt();
    final r = bytesToHex(sig.sublist(1, 1 + 32));
    final s = bytesToHex(sig.sublist(1 + 32, 1 + 32 + 32));

    var truncChainId = chainId ?? 1;
    while (truncChainId.bitLength > 32) {
      truncChainId >>= 8;
    }

    final truncTarget = truncChainId * 2 + 35;

    int parity = v;
    if (truncTarget & 0xff == v) {
      parity = 0;
    } else if ((truncTarget + 1) & 0xff == v) {
      parity = 1;
    }

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    int chainIdV;
    if (isEIP1559) {
      chainIdV = v;
    } else {
      chainIdV = chainId != null ? (parity + (chainId * 2 + 35)) : parity;
    }

    return MsgSignature(
        BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), chainIdV);
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload,
      {int? chainId}) async {
    if (isNotConnected) throw exception.DeviceNotConnectedException();

    final sig = await ethereumLedgerApp!.signMessage(payload);

    final r = sig.sublist(1, 1 + 32);
    final s = sig.sublist(1 + 32, 1 + 32 + 32);
    final v = [sig[0]];

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
    return Uint8List.fromList(r + s + v);
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnimplementedError(
          "EvmLedgerCredentials.signPersonalMessageToUint8List");

  Future<void> provideERC20Info(
      String erc20ContractAddress, int chainId) async {
    if (isNotConnected) throw exception.DeviceNotConnectedException();

    try {
      await ethereumLedgerApp!.getAndProvideERC20TokenInformation(
          erc20ContractAddress: erc20ContractAddress, chainId: chainId);
    } catch (e) {
      printV(e);
      rethrow;
      // if (e.errorCode != -28672) rethrow;
    }
  }

  bool get isNotConnected => ethereumLedgerApp == null || ethereumLedgerApp!.connection.isDisconnected;
}
