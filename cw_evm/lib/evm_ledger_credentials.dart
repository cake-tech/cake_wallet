import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/device_not_connected_exception.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/src/crypto/secp256k1.dart';
import 'package:web3dart/web3dart.dart';

class EvmLedgerCredentials extends CredentialsWithKnownAddress {
  final String _address;
  LedgerDevice? device;

  EvmLedgerCredentials(this._address) {
    print("EvmLedgerCredentials: $_address");
  }

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void connect(LedgerDevice device) {
    // TODO: (Konsti) Listener for ConnectionUpdate to reset device to null
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    print("signToEcSignature: $payload");

    if (device == null) throw DeviceNotConnectedException();

    // TODO: (Konsti) Send Payload for signing to ledger
    throw UnimplementedError();
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    print("signToSignature: $payload");
    // TODO: (Konsti) implement signToSignature
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    print("signPersonalMessage: $payload");
    // TODO: (Konsti) implement signToSignature
    throw UnimplementedError();
  }

  @override
  Uint8List signPersonalMessageToUint8List(Uint8List payload, {int? chainId}) {
    print("signPersonalMessageToUint8List: $payload");
    // TODO: (Konsti) implement signToSignature
    throw UnimplementedError();
  }
}
