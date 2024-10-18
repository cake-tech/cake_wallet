import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:monero/monero.dart' as monero;

Timer? _ledgerExchangeTimer;
String _lastLedgerRequest = '';

void enableLedgerExchange(monero.wallet ptr, LedgerConnection connection) {
  _ledgerExchangeTimer = Timer.periodic(Duration(milliseconds: 1), (_) async {
    final ledgerRequestLength = monero.Wallet_getSendToDeviceLength(ptr);
    final ledgerRequest = monero.Wallet_getSendToDevice(ptr)
        .cast<Uint8>()
        .asTypedList(ledgerRequestLength);
    if (ledgerRequestLength > 0 && _lastLedgerRequest != ledgerRequest.join()) {
      _lastLedgerRequest = ledgerRequest.join();

      final response = await exchange(connection, ledgerRequest);

      final Pointer<Uint8> result = malloc<Uint8>(response.length);
      for (var i = 0; i < response.length; i++) {
        result.asTypedList(response.length)[i] = response[i];
      }

      monero.Wallet_setDeviceReceivedData(
          ptr, result.cast<UnsignedChar>(), response.length);

      monero.Wallet_setDeviceSendData(
          ptr, malloc<Uint8>(0).cast<UnsignedChar>(), 0);
    }
  });
}

void disableLedgerExchange() {
  _ledgerExchangeTimer?.cancel();
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
