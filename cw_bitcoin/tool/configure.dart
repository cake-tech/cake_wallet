import 'dart:io';

const payjoinOutputPath = 'lib/payjoin/payjoin.dart';
const spScannerOutputPath = 'lib/silent_payments/sp.dart';
const pubspecOutputPath = 'pubspec.yaml';

Future<void> main(List<String> args) async {
  const prefix = '--';
  final hasPayjoin = args.contains('${prefix}payjoin');
  final hasSpScanner = args.contains('${prefix}sp-scanner');

  await generatePayjoin(hasPayjoin);
  await generateSpScanner(hasSpScanner);

  await generatePubspec(hasPayjoin: hasPayjoin, hasSpScanner: hasSpScanner);
}

Future<void> generatePayjoin(bool hasImplementation) async {
  final outputFile = File(payjoinOutputPath);

  var output = '';

  if (!hasImplementation) {
    final payjoinCommonHeaders = """
import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:cw_bitcoin/bitcoin_wallet.dart';
""";

    final payjoinEmptyDefinition = 'PayjoinManager? payjoinManager;\n';

    final payjoinCommonContent = """
enum PayjoinSenderRequestTypes {
  requestPosted,
  psbtToSign;
}

PayjoinManager? cwPayjoinManager;

abstract class PayjoinManager {
  dynamic currentPayjoinReceiver;

  static const List<String> ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
    'https://ohttp.cakewallet.com',
  ];

  static String randomOhttpRelayUrl() =>
      ohttpRelayUrls[Random.secure().nextInt(ohttpRelayUrls.length)];

  static const payjoinDirectoryUrl = 'https://payjo.in';

  void init({required dynamic payjoinStorage, required BitcoinWalletBase wallet});

  Future<void> initPayjoin();

  Future<void> resumeSessions();

  Future<dynamic> initSender(String pjUriString, String originalPsbt, int networkFeesSatPerVb);

  Future<void> spawnNewSender({
    required dynamic sender,
    required String pjUrl,
    required BigInt amount,
    bool isTestnet = false,
  });

  Future<dynamic> getUnusedReceiver(String address, [bool isTestnet = false]);

  Future<dynamic> initReceiver(String address, [bool isTestnet = false]);

  Future<void> spawnReceiver({
    required dynamic receiver,
    bool isTestnet = false,
  });

  void cleanupSessions();
}

class PayjoinPollerSession {
  final Isolate isolate;
  final ReceivePort port;

  PayjoinPollerSession(this.isolate, this.port);

  void close() {
    isolate.kill();
    port.close();
  }
}""";

    output = '$payjoinCommonHeaders\n' + payjoinEmptyDefinition + '\n' + payjoinCommonContent;
  } else {
    final payjoinCWHeaders = """
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/payjoin/payjoin_session_errors.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_bitcoin/psbt/utils.dart';
import 'package:cw_core/utils/print_verbose.dart';

import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive.dart';
import 'package:payjoin_flutter/send.dart';
import 'package:payjoin_flutter/src/config.dart' as pj_config;
import 'package:payjoin_flutter/src/generated/api.dart' as pj_api;
import 'package:payjoin_flutter/src/generated/frb_generated.dart' as pj;
import 'package:payjoin_flutter/src/generated/api/send/error.dart' as pj_error;
import 'package:payjoin_flutter/uri.dart' as PayjoinUri;
import 'package:payjoin_flutter/src/generated/api/receive.dart';
import 'package:payjoin_flutter/src/generated/api/send.dart';
import 'package:payjoin_flutter/bitcoin_ffi.dart' as bitcoin_ffi;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as very_insecure_http_do_not_use; // for errors

import 'package:cw_core/payjoin_session.dart';
import 'package:hive/hive.dart';
""";

    final payjoinCWPart = """
part 'manager.dart';
part 'payjoin_send_worker.dart';
part 'payjoin_receive_worker.dart';
part 'payjoin_persister.dart';
part 'storage.dart';
""";

    final payjoinCWDefinition = 'PayjoinManager? cwPayjoinManager = CWPayjoinManager();\n';

    final payjoinContent = """
enum PayjoinSenderRequestTypes {
  requestPosted,
  psbtToSign;
}

abstract class PayjoinManager {
  dynamic currentPayjoinReceiver;

  static const List<String> ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
    'https://ohttp.cakewallet.com',
  ];

  static String randomOhttpRelayUrl() =>
      ohttpRelayUrls[Random.secure().nextInt(ohttpRelayUrls.length)];

  static const payjoinDirectoryUrl = 'https://payjo.in';

  void init({required dynamic payjoinStorage, required BitcoinWalletBase wallet});

  Future<void> initPayjoin();

  Future<void> resumeSessions();

  Future<dynamic> initSender(String pjUriString, String originalPsbt, int networkFeesSatPerVb);

  Future<void> spawnNewSender({
    required dynamic sender,
    required String pjUrl,
    required BigInt amount,
    bool isTestnet = false,
  });

  Future<dynamic> getUnusedReceiver(String address, [bool isTestnet = false]);

  Future<dynamic> initReceiver(String address, [bool isTestnet = false]);

  Future<void> spawnReceiver({
    required dynamic receiver,
    bool isTestnet = false,
  });

  void cleanupSessions();
}

class PayjoinPollerSession {
  final Isolate isolate;
  final ReceivePort port;

  PayjoinPollerSession(this.isolate, this.port);

  void close() {
    isolate.kill();
    port.close();
  }
}""";

    output =
        '$payjoinCWHeaders\n' + payjoinCWPart + '\n' + payjoinCWDefinition + '\n' + payjoinContent;
  }

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateSpScanner(bool hasImplementation) async {
  final outputFile = File(spScannerOutputPath);
  var output = "";

  if (!hasImplementation) {
    final spCommonHeaders = """
import 'dart:async';

import 'package:cw_bitcoin/electrum_wallet.dart';
""";

    const spEmptyDefinition = 'SilentPayments? silentPayments;\n';

    final spCommonContent = """
abstract class SilentPayments {
  Future<void> handleScanSilentPayments(ScanData scanData);
}""";

    output = '$spCommonHeaders\n' + '$spEmptyDefinition\n' + '$spCommonContent';
  } else {
    final spCwHeaders = """
import 'dart:async';
import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:sp_scanner/sp_scanner.dart';
""";

    final spCwPart = """
part 'cw_sp.dart';
""";

    final spCwDefinition = 'SilentPayments? silentPayments = CWSilentPayments();\n';

    final spCwContent = """
abstract class SilentPayments {
  Future<void> handleScanSilentPayments(ScanData scanData);
}""";

    output = '$spCwHeaders\n' + '$spCwPart\n' + '$spCwDefinition\n' + '$spCwContent';
  }

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generatePubspec({required bool hasPayjoin, required bool hasSpScanner}) async {
  final inputFile = File(pubspecOutputPath);
  final inputText = await inputFile.readAsString();
  final inputLines = inputText.split('\n');
  final dependenciesIndex = inputLines.indexWhere((line) => Platform.isWindows
      // On Windows it could contains `\r` (Carriage Return). It could be fixed in newer dart versions.
      ? line.toLowerCase() == 'dependencies:\r' || line.toLowerCase() == 'dependencies:'
      : line.toLowerCase() == 'dependencies:');

  var output = '';

  if (hasPayjoin) {
    final cwPayjoin = """
  payjoin_flutter:
    git:
      url: https://github.com/OmarHatem28/payjoin-flutter
      ref: da83a23f3a011cb49eb3b6513cd485b3fb8867ff #cake-v2
    """;
    output += "\n$cwPayjoin";
  }

  if (hasSpScanner) {
    final cwSpScanner = """
  sp_scanner:
    git:
      url: https://github.com/cake-tech/sp_scanner
      ref: sp_v4.0.0
    """;
    output += "\n$cwSpScanner";
  }

  final outputLines = output.split('\n');
  inputLines.insertAll(dependenciesIndex + 1, outputLines);
  final outputContent = inputLines.join('\n');
  final outputFile = File(pubspecOutputPath);

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(outputContent);
}
