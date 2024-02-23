import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/device_not_connected_exception.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/crypto/secp256k1.dart';
import 'package:web3dart/web3dart.dart';

class EvmLedgerCredentials extends CredentialsWithKnownAddress {
  final String _address;
  LedgerDevice? device;

  final Ledger ledger = Ledger(options: LedgerOptions(connectionTimeout: const Duration(seconds: 10)));

  late final StreamSubscription<BleStatus> ledgerSubscription;

  EvmLedgerCredentials(this._address);

  @override
  EthereumAddress get address => EthereumAddress.fromHex(_address);

  void connect(LedgerDevice device) {
    this.device = device;
    ledgerSubscription = ledger.statusStateChanges.listen((state) => print(state));
    // TODO: (Konsti) Listener for ConnectionUpdate to reset device to null
  }

  @override
  MsgSignature signToEcSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) {
    // TODO: (Konsti) Send Payload for signing to ledger
    throw UnimplementedError();
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId, bool isEIP1559 = false}) async {
    if (device == null) throw DeviceNotConnectedException();
    final ethereumLedgerApp = EthereumLedgerApp(ledger);

    await ledger.connect(device!);

    final sig = await ethereumLedgerApp.signTransaction(device!, payload);


    final v = sig[0].toInt();
    final r = bytesToHex(sig.sublist(1, 1 + 32));
    final s = bytesToHex(sig.sublist(1 + 32, 1 + 32 + 32));

    return MsgSignature(BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), v);
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
