import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_zcash/src/zcash_network.dart';
import 'package:cw_zcash/src/zcash_wallet.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/ledger.dart' as zkool_ledger;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;

/// Zcash on a Ledger running the Official Zcash app (LedgerHQ app-zcash).
///
/// The device only ever sees APDUs. The Rust side speaks the app's PCZT
/// protocol -- viewing-key export, transaction review, Ironwood (NU6.3) and
/// transparent signing -- and hands every command to [exchange], which sends
/// it over the BLE or USB connection that ledger_flutter_plus owns. Proofs and
/// the binding signature are computed by the backend afterwards.
/// A Ledger problem in the words of the person holding the device. Shown as
/// is, without an "Exception:" prefix or the signer's backtrace.
class ZcashLedgerException implements Exception {
  ZcashLedgerException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _notConnected =
    "The Ledger is not connected. Make sure it is unlocked and nearby, then try again.";

class ZcashLedgerService extends HardwareWalletService {
  ZcashLedgerService(this.connection);

  final LedgerConnection connection;

  /// Ironwood/v6 signing shipped in app-zcash 3.9.2.
  static const (int, int, int) minAppVersion = (3, 9, 2);

  /// Why the last APDU failed on the transport, if it did. Rust only sees an
  /// empty reply in that case, so the cause is kept here and put on the error
  /// the caller gets.
  Object? lastTransportError;

  /// Sends one APDU and returns the raw reply, status word included.
  ///
  /// A failure of the connection itself answers with nothing: the Rust side
  /// turns that into an error, and [_guard] attaches the reason. A status
  /// word the transport already turned into an exception is put back on the
  /// wire so the protocol code can read it (a refusal on the device is 0x6985
  /// and must reach the user as such).
  Future<Uint8List> exchange(final Uint8List apdu) async {
    try {
      final reply = await connection.sendOperation<Uint8List>(_ApduOperation(apdu));
      // A cause recorded for an earlier exchange no longer explains a later
      // failure.
      lastTransportError = null;
      return reply;
    } on LedgerDeviceException catch (e) {
      printV("ledger: status ${e.errorCode.toRadixString(16)} for ins ${apdu[1].toRadixString(16)}");
      return Uint8List.fromList([(e.errorCode >> 8) & 0xff, e.errorCode & 0xff]);
    } catch (e) {
      printV("ledger transport error: $e");
      lastTransportError = e;
      return Uint8List(0);
    }
  }

  /// Version of the app open on the device, e.g. "3.9.3".
  Future<String> appVersion() => _guard(() => zkool_ledger.ledgerAppVersion(exchange: exchange));

  /// Fails unless the Zcash app is open and new enough to sign Ironwood.
  Future<void> ensureZcashApp() async {
    final String version;
    try {
      version = await appVersion();
    } on ZcashLedgerException {
      // Already in the user's words: locked, wrong app, not connected.
      rethrow;
    } catch (e) {
      throw ZcashLedgerException(
        "Open the Zcash app on your Ledger, then try again (${firstLine(e)})",
      );
    }
    final parts = version.split('.').map(int.tryParse).toList();
    if (parts.length < 3 || parts.any((final p) => p == null)) {
      // Never skip the minimum-version check on a version we cannot read.
      throw ZcashLedgerException(
        "Could not read the Zcash app version on the Ledger ($version); "
        "update the app in Ledger Live.",
      );
    }
    final (major, minor, patch) = minAppVersion;
    final current = (parts[0]!, parts[1]!, parts[2]!);
    final tooOld = current.$1 < major ||
        (current.$1 == major && current.$2 < minor) ||
        (current.$1 == major && current.$2 == minor && current.$3 < patch);
    if (tooOld) {
      throw ZcashLedgerException(
        "Zcash app $version on the Ledger is too old for shielded transactions; "
        "update it to $major.$minor.$patch or newer in Ledger Live.",
      );
    }
  }

  /// Has the device show the account's default unified address on its own
  /// screen and returns it once the user approves there.
  ///
  /// The screen is the one part of the path a tampered link cannot alter, so
  /// the caller shows the address it derived from the imported viewing key
  /// at the same time and the user compares the two.
  Future<String> showAddressOnDevice({
    required final int aindex,
    final ZcashNetwork network = ZcashNetwork.mainnet,
  }) async {
    await ZcashWalletBase.ensureRustLib();
    await ensureZcashApp();
    final coin = zkool_coin.Coin(defaultCoin: network.networkIndex);
    return _guard(
      () => zkool_ledger.ledgerShowAddress(aindex: aindex, c: coin, exchange: exchange),
    );
  }

  /// Exports the viewing key of one ZIP-32 account.
  ///
  /// Every export is approved on the device screen, so this returns a single
  /// account regardless of [limit]: the picker's "load more" asks for the
  /// next index, one approval at a time. [HardwareAccountData.xpub] carries
  /// the unified full viewing key the wallet is created from.
  ///
  /// [network] selects the viewing key's network (mainnet unless the wallet
  /// being restored says otherwise); it decides the coin type in the
  /// derivation path the device exports from.
  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    final int index = 0,
    final int limit = 5,
    final ZcashNetwork network = ZcashNetwork.mainnet,
  }) async {
    await ZcashWalletBase.ensureRustLib();
    await ensureZcashApp();
    // Only the network is read from this, never the database.
    final coin = zkool_coin.Coin(defaultCoin: network.networkIndex);
    final ufvk = await _guard(
      () => zkool_ledger.ledgerGetUfvk(aindex: index, c: coin, exchange: exchange),
    );
    final address = zkool_ledger.ufvkDefaultAddress(ufvk: ufvk, c: coin);
    return [
      HardwareAccountData(
        address: address,
        accountIndex: index,
        derivationPath: "m/32'/${network == ZcashNetwork.mainnet ? 133 : 1}'/$index'",
        xpub: ufvk,
      ),
    ];
  }

  /// Has the device review and sign a transaction plan. Progress events are
  /// followed by the proven, finalized package ready to broadcast.
  Stream<zkool_pay.SigningEvent> sign(
    final zkool_pay.PcztPackage package,
    final zkool_coin.Coin coin,
  ) async* {
    // The connection may have been made minutes ago with any app open on the
    // device; make sure it is the Zcash app before the transaction is sent,
    // so a wrong app is reported as such rather than as a rejected header.
    await ZcashWalletBase.ensureRustLib();
    await ensureZcashApp();
    if (connection.isDisconnected) {
      throw ZcashLedgerException(_notConnected);
    }
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
    final cause = lastTransportError;
    if (cause != null) {
      // The exchange itself failed: the device went away, out of range, or
      // was locked long enough to drop the link. The cause stays in the log.
      printV("ledger transport failure: $cause");
      return ZcashLedgerException(_notConnected);
    }
    return statusWordOf(error) == null ? error : ZcashLedgerException(describe(error));
  }

  /// The status word in an error the Rust signer raised for an APDU the
  /// device answered with a failure, or null if the error is something else.
  /// The signer reports these as "Error Executing Instruction <ins>: <sw>",
  /// both in decimal.
  static int? statusWordOf(final Object error) {
    final m = RegExp(r"Error Executing Instruction \d+: (\d+)").firstMatch(error.toString());
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  /// What a Ledger status word means to the person holding the device.
  static String describe(final Object error) {
    final sw = statusWordOf(error);
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
      case null:
        return firstLine(error);
      default:
        return "The Ledger returned an error (0x${sw.toRadixString(16).padLeft(4, '0')}). "
            "Make sure the Zcash app is open and up to date, then try again.";
    }
  }

  /// An error's message without the Rust backtrace the signer appends.
  static String firstLine(final Object error) {
    var text = error.toString();
    if (text.startsWith("Exception: ")) {
      text = text.substring("Exception: ".length);
    }
    final cut = text.indexOf("\n\nStack backtrace");
    if (cut != -1) {
      text = text.substring(0, cut);
    }
    return text.trim().replaceFirst(RegExp(r"^AnyhowException\("), "").replaceFirst(RegExp(r"\)$"), "");
  }
}

/// One APDU in, its full reply out, no interpretation in between.
class _ApduOperation extends LedgerRawOperation<Uint8List> {
  _ApduOperation(this.apdu);

  final Uint8List apdu;

  @override
  Future<List<Uint8List>> write(final ByteDataWriter writer) async => [apdu];

  @override
  Future<Uint8List> read(final ByteDataReader reader) async =>
      reader.read(reader.remainingLength);
}
