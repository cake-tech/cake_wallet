import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/device_not_connected_exception.dart' as exception;
import 'package:trezor_connect/trezor_connect.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../utils/rlp_decode.dart' as rlp;

class EvmTrezorCredentials extends CredentialsWithKnownAddress {
  final String _address;

  TrezorConnect? trezorConnect;
  String? derivationPath;

  EvmTrezorCredentials(this._address);

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void setTrezorConnect(TrezorConnect connection, [String? derivationPath_]) {
    trezorConnect = connection;
    derivationPath = derivationPath_ ?? "m/44'/60'/0'/0/0";
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) =>
      throw UnimplementedError("EvmLedgerCredentials.signToEcSignature");

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) async {
    if (trezorConnect == null) {
      throw exception.DeviceNotConnectedException();
    }

    if (isEIP1559) payload = payload.sublist(1);

    final data = rlp.decode(payload);

    TrezorEthereumTransaction tx;
    if (isEIP1559) {
      final chainId = data[0][0];
      final nonce = bytesToHex(data[1], include0x: true);
      final maxPriorityFeePerGas = bytesToHex(data[2], include0x: true);
      final maxFeePerGas = bytesToHex(data[3], include0x: true);
      final maxGas = bytesToHex(data[4], include0x: true);
      final to = bytesToHex(data[5], include0x: true);
      final value = bytesToHex(data[6], include0x: true);
      final txData = bytesToHex(data[7], include0x: true);

      tx = TrezorEthereumTransaction(
        to: to,
        value: value,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        gasLimit: maxGas,
        nonce: nonce,
        chainId: chainId,
        data: txData,
      );
    } else {
      final nonce = bytesToHex(data[0]);
      final gasPrice = bytesToHex(data[1]);
      final maxGas = bytesToHex(data[2]);
      final to = bytesToHex(data[3]);
      final value = bytesToHex(data[4]);
      final txData = bytesToHex(data[5]);
      tx = TrezorEthereumTransaction(
        to: to,
        value: value,
        gasPrice: gasPrice,
        gasLimit: maxGas,
        nonce: nonce,
        chainId: chainId ?? 1,
        data: txData,
      );
    }

    final sig = (await trezorConnect!.ethereumSignTransaction(derivationPath!, transaction: tx))!;

    final v = int.parse(strip0x(sig.v), radix: 16);

    if (isEIP1559) {
      return MsgSignature(
          BigInt.parse(strip0x(sig.r), radix: 16), BigInt.parse(strip0x(sig.s), radix: 16), v);
    }

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
    final chainIdV = chainId != null ? (parity + (chainId * 2 + 35)) : parity;

    return MsgSignature(
        BigInt.parse(strip0x(sig.r), radix: 16), BigInt.parse(strip0x(sig.s), radix: 16), chainIdV);
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) async {
    if (isNotConnected) throw exception.DeviceNotConnectedException();
    return hexToBytes((await trezorConnect!
                .ethereumSignMessage(derivationPath!, message: bytesToHex(payload), hex: true))
            ?.signature ??
        '');
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) =>
      throw UnimplementedError("EvmLedgerCredentials.signPersonalMessageToUint8List");

  bool get isNotConnected => trezorConnect == null;
}
