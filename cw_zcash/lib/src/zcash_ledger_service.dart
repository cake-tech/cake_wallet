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
    } catch (e) {
      // Any other app answers the version probe with an error status word;
      // the wrong-app code is what the UI already knows how to explain.
      throw Exception("Open the Zcash app on your Ledger (0x6e01): $e");
    }
    final parts = version.split('.').map(int.tryParse).toList();
    if (parts.length < 3 || parts.any((final p) => p == null)) {
      // Never skip the minimum-version check on a version we cannot read.
      throw Exception(
        "Could not read the Zcash app version on the Ledger ($version); "
        "update the app in Ledger Live",
      );
    }
    final (major, minor, patch) = minAppVersion;
    final current = (parts[0]!, parts[1]!, parts[2]!);
    final tooOld = current.$1 < major ||
        (current.$1 == major && current.$2 < minor) ||
        (current.$1 == major && current.$2 == minor && current.$3 < patch);
    if (tooOld) {
      throw Exception(
        "Zcash app $version on the Ledger is too old for shielded transactions; "
        "update it to $major.$minor.$patch or newer in Ledger Live",
      );
    }
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
    lastTransportError = null;
    yield* zkool_ledger
        .ledgerSignTransaction(package: package, c: coin, exchange: exchange)
        .handleError((final Object e) => throw _withTransportCause(e));
  }

  Future<T> _guard<T>(final Future<T> Function() call) async {
    lastTransportError = null;
    try {
      return await call();
    } catch (e) {
      throw _withTransportCause(e);
    }
  }

  Object _withTransportCause(final Object error) {
    final cause = lastTransportError;
    if (cause == null) {
      return error;
    }
    return Exception("Ledger connection failed: $cause ($error)");
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
