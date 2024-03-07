import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/device_not_connected_exception.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EvmLedgerCredentials extends CredentialsWithKnownAddress {
  final String _address;

  Ledger? ledger;
  EthereumLedgerApp? ethereumLedgerApp;

  EvmLedgerCredentials(this._address);

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void setLedger(Ledger setLedger) {
    ledger = setLedger;
    ethereumLedgerApp = EthereumLedgerApp(ledger!);
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    // TODO: (Konsti) implement waitFor signToSignature
    throw UnimplementedError("EvmLedgerCredentials.signToEcSignature");
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) async {
    if (ledger?.devices.isNotEmpty != true) throw DeviceNotConnectedException();
    final device = ledger!.devices.first;

    final sig = await ethereumLedgerApp!.signTransaction(device, payload);

    final v = sig[0].toInt();
    final r = bytesToHex(sig.sublist(1, 1 + 32));
    final s = bytesToHex(sig.sublist(1 + 32, 1 + 32 + 32));

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    int chainIdV;
    if (isEIP1559) {
      chainIdV = v;
    } else {
      chainIdV = chainId != null
          ? (v + (chainId * 2 + 35))
          : v;
    }

    await ledger!.disconnect(device);

    print("chainId: $chainId, chainIdV: $chainIdV, v: $v");

    return MsgSignature(BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), chainIdV);
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) async {
    if (ledger?.devices.isNotEmpty != true) throw DeviceNotConnectedException();
    final device = ledger!.devices.first;

    final sig = await ethereumLedgerApp!.signMessage(device, payload);

    final r = sig.sublist(1, 1 + 32);
    final s = sig.sublist(1 + 32, 1 + 32 + 32);
    final v = [sig[0]];

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
    return Uint8List.fromList(r + s + v);
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) {
    // TODO: (Konsti) implement waitFor signToSignature
    throw UnimplementedError("EvmLedgerCredentials.signPersonalMessageToUint8List");
  }

  Future<void> provideERC20Info(String erc20ContractAddress, int chainId) async {
    if (ledger?.devices.isNotEmpty != true) throw DeviceNotConnectedException();
    final device = ledger!.devices.first;
    try {
      await ethereumLedgerApp!.getAndProvideERC20TokenInformation(device,
          erc20ContractAddress: erc20ContractAddress, chainId: chainId);
    } on LedgerException catch (e) {
      if (e.errorCode != -28672) rethrow;
    }
  }
}
