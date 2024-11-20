import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:monero/monero.dart' as monero;
// import 'package:polyseed/polyseed.dart';

LedgerConnection? gLedger;

Timer? _ledgerExchangeTimer;
Timer? _ledgerKeepAlive;

void enableLedgerExchange(monero.wallet ptr, LedgerConnection connection) {
  _ledgerExchangeTimer?.cancel();
  _ledgerExchangeTimer = Timer.periodic(Duration(milliseconds: 1), (_) async {
    final ledgerRequestLength = monero.Wallet_getSendToDeviceLength(ptr);
    final ledgerRequest = monero.Wallet_getSendToDevice(ptr)
        .cast<Uint8>()
        .asTypedList(ledgerRequestLength);
    if (ledgerRequestLength > 0) {
      _ledgerKeepAlive?.cancel();

      final Pointer<Uint8> emptyPointer = malloc<Uint8>(0);
      monero.Wallet_setDeviceSendData(
          ptr, emptyPointer.cast<UnsignedChar>(), 0);
      malloc.free(emptyPointer);

      // print("> ${ledgerRequest.toHexString()}");
      final response = await exchange(connection, ledgerRequest);
      // print("< ${response.toHexString()}");

      final Pointer<Uint8> result = malloc<Uint8>(response.length);
      for (var i = 0; i < response.length; i++) {
        result.asTypedList(response.length)[i] = response[i];
      }

      monero.Wallet_setDeviceReceivedData(
          ptr, result.cast<UnsignedChar>(), response.length);
      malloc.free(result);
      keepAlive(connection);
    }
  });
}

void keepAlive(LedgerConnection connection) {
  if (connection.connectionType == ConnectionType.ble) {
    _ledgerKeepAlive = Timer.periodic(Duration(seconds: 10), (_) async {
      try {
        UniversalBle.setNotifiable(
          connection.device.id,
          connection.device.deviceInfo.serviceId,
          connection.device.deviceInfo.notifyCharacteristicKey,
          BleInputProperty.notification,
        );
      } catch (_) {}
    });
  }
}

void disableLedgerExchange() {
  _ledgerExchangeTimer?.cancel();
  _ledgerKeepAlive?.cancel();
  gLedger?.disconnect();
  gLedger = null;
}

Future<Uint8List> exchange(LedgerConnection connection, Uint8List data) async =>
    connection.sendOperation<Uint8List>(ExchangeOperation(data));

class ExchangeOperation extends LedgerRawOperation<Uint8List> {
  final Uint8List inputData;

  ExchangeOperation(this.inputData);

  @override
  Future<Uint8List> read(ByteDataReader reader) async =>
      reader.read(reader.remainingLength);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async => [inputData];
}
