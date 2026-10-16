import 'dart:async';
import "dart:convert";
import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/utils/print_verbose.dart';
import "package:cw_zcash/src/hardware/zcash_hardware_wallet_service.dart";
import 'package:cw_zcash/src/zcash_network.dart';
import 'package:cw_zcash/src/zcash_wallet.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/ledger.dart' as zkool_ledger;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;

class ZcashLedgerException implements Exception {
  ZcashLedgerException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _notConnected =
    "The Ledger is not connected. Make sure it is unlocked and nearby, then try again.";

class ZcashLedgerService extends ZcashHardwareWalletService {
  ZcashLedgerService(this.connection, {this.network = ZcashNetwork.mainnet, zkool_coin.Coin? coin})
    : super(coin);

  final LedgerConnection connection;
  final ZcashNetwork network;

  @override
  ZcashLedgerService withCoin(zkool_coin.Coin coin) =>
      ZcashLedgerService(connection, network: network, coin: coin);

  /// Ironwood/v6 signing shipped in app-zcash 3.9.2.
  static const (int, int, int) minAppVersion = (3, 9, 2);

  Object? lastTransportError;

  Future<Uint8List> exchange(final Uint8List apdu) async {
    try {
      final reply = await connection.sendOperation<Uint8List>(_ExchangeOperation(apdu));
      lastTransportError = null;
      return reply;
    } on LedgerDeviceException catch (e) {
      printV(
        "ledger: status ${e.errorCode.toRadixString(16)} for ins ${apdu[1].toRadixString(16)}");
      return Uint8List.fromList([(e.errorCode >> 8) & 0xff, e.errorCode & 0xff]);
    } catch (e) {
      printV("ledger transport error: $e");
      lastTransportError = e;
      return Uint8List(0);
    }
  }

  Future<String> appVersion() => _guard(() => zkool_ledger.ledgerAppVersion(exchange: exchange));

  /// Fails unless the Zcash app is open and new enough to sign Ironwood.
  Future<void> ensureZcashApp() async {
    final String version;
    try {
      version = await appVersion();
    } on ZcashLedgerException {
      rethrow;
    } catch (e) {
      throw ZcashLedgerException(
        "Open the Zcash app on your Ledger, then try again (${_trimRustException(e.toString())})");
    }
    final parts = version.split(".").map(int.tryParse).toList();
    if (parts.length < 3 || parts.any((final p) => p == null)) {
      throw ZcashLedgerException("Could not read the Zcash app version on the Ledger ($version)");
    }
    final (major, minor, patch) = minAppVersion;
    final current = (parts[0]!, parts[1]!, parts[2]!);
    final tooOld =
        current.$1 < major ||
        (current.$1 == major && current.$2 < minor) ||
        (current.$1 == major && current.$2 == minor && current.$3 < patch);
    if (tooOld) {
      throw ZcashLedgerException(
        "Zcash app $version on the Ledger is too old for shielded transactions");
    }
  }

  Future<void> _ensureServiceReadiness() async {
    await ZcashWalletBase.ensureRustLib();
    await ensureZcashApp();
    if (coin == null) {
      throw ZcashLedgerException("Zcash coin not set, please contact support");
    }
  }

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    await _ensureServiceReadiness();
    final ufvk = await _guard(
      () => zkool_ledger.ledgerGetUfvk(aindex: index, c: coin!, exchange: exchange),
    );
    final address = zkool_ledger.ufvkDefaultAddress(ufvk: ufvk, c: coin!);
    return [
      HardwareAccountData(
        address: address,
        accountIndex: index,
        derivationPath: "m/44'/${network == ZcashNetwork.mainnet ? 133 : 1}'/$index'",
        xpub: ufvk,
      ),
    ];
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) async {
    await _ensureServiceReadiness();
    final txPlan = await zkool_pay.unpackTransaction(bytes: base64Decode(transaction));

    await for (final event in _sign(txPlan, coin!)) {
      switch (event) {
        case zkool_pay.SigningEvent_Progress(:final field0):
          printV("ledger: $field0");
        case zkool_pay.SigningEvent_Result(:final field0):
          return zkool_pay.packTransaction(pczt: field0);
      }
    }
    throw ZcashLedgerException("Ledger did not sign the transaction");
  }

  Stream<zkool_pay.SigningEvent> _sign(
    final zkool_pay.PcztPackage package,
    final zkool_coin.Coin coin,
  ) async* {
    lastTransportError = null;
    yield* zkool_ledger
        .ledgerSignTransaction(package: package, c: coin, exchange: exchange)
        .handleError((final Object e) => throw _withTransportCause(e));
  }

  Future<T> _guard<T>(final Future<T> Function() call) async {
    if (connection.isDisconnected) {
      throw ZcashLedgerException(_notConnected);
    }
    lastTransportError = null;
    try {
      return await call();
    } catch (e) {
      throw _withTransportCause(e);
    }
  }

  Object _withTransportCause(final Object error) {
    if (error is ZcashLedgerException) {
      return error;
    }
    if (lastTransportError != null) {
      printV("ledger transport failure: $lastTransportError");
      return ZcashLedgerException(_notConnected);
    }

    final sw = _ledgerStatusWordOf(error);
    return sw == null ? error : ZcashLedgerException(_interpretLedgerErrorCode(sw));
  }

  int? _ledgerStatusWordOf(final Object error) {
    final m = RegExp(r"Error Executing Instruction \d+: (\d+)").firstMatch(error.toString());
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  String _interpretLedgerErrorCode(int sw) {
    switch (sw) {
      case 0x5515:
        return "Your Ledger is locked. Unlock it and open the Zcash app, then try again.";
      case 0x6e00:
      case 0x6e01:
      case 0x6d00:
      case 0x6d02:
        return "Open the Zcash app on your Ledger, then try again.";
      case 0x6985:
      case 0x6986:
        return "The transaction was rejected on the Ledger.";
      case 0x6a80:
      case 0x6a86:
      case 0x6a87:
        return "The Ledger could not read the transaction. Update the Zcash app in Ledger Live and try again.";
      case 0x6f00:
      case 0x6f01:
        return "The Zcash app on the Ledger ran into an internal error. Close and reopen the app, then try again.";
      default:
        return "The Ledger returned an error (0x${sw.toRadixString(16).padLeft(4, '0')}). Make sure the Zcash app is open and up to date, then try again.";
    }
  }

  String _trimRustException(String error) {
    if (error.startsWith("Exception: ")) {
      error = error.substring("Exception: ".length);
    }
    final cut = error.indexOf("\n\nStack backtrace");
    if (cut != -1) {
      error = error.substring(0, cut);
    }
    return error
        .trim()
        .replaceFirst(RegExp(r"^AnyhowException\("), "")
        .replaceFirst(RegExp(r"\)$"), "");
  }
}

class _ExchangeOperation extends LedgerRawOperation<Uint8List> {
  _ExchangeOperation(this.inputData);

  final Uint8List inputData;

  @override
  Future<Uint8List> read(ByteDataReader reader) async => reader.read(reader.remainingLength);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async => [inputData];
}
