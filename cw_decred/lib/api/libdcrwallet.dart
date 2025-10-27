import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_decred/api/libdcrwallet_bindings.dart';
import 'package:cw_decred/api/util.dart';

final int ErrCodeNotSynced = 1;

final String libraryName = Platform.isAndroid || Platform.isLinux // TODO: Linux.
    ? 'libdcrwallet.so'
    : 'cw_decred.framework/cw_decred';

class Libwallet {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  static Future<Libwallet> spawn() async {
    // Create a receive port and add its initial message handler.
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };
    // Spawn the isolate.
    try {
      await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return Libwallet._(receivePort, sendPort);
  }

  Libwallet._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    final dcrwalletApi = libdcrwallet(DynamicLibrary.open(libraryName));
    receivePort.listen((message) {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (int id, Map<String, String> args) = message as (int, Map<String, String>);
      var res = PayloadResult("", "", 0);
      final method = args["method"] ?? "";
      try {
        switch (method) {
          case "initlibdcrwallet":
            final logDir = args["logdir"] ?? "";
            final level = args["level"] ?? "";
            final cLogDir = logDir.toCString();
            final cLevel = level.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.initialize(cLogDir, cLevel),
              ptrsToFree: [cLogDir, cLevel],
            );
            break;
          case "createwallet":
            final config = args["config"] ?? "";
            final cConfig = config.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.createWallet(cConfig),
              ptrsToFree: [cConfig],
            );
            break;
          case "createwatchonlywallet":
            final config = args["config"] ?? "";
            final cConfig = config.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.createWatchOnlyWallet(cConfig),
              ptrsToFree: [cConfig],
            );
            break;
          case "loadwallet":
            final config = args["config"] ?? "";
            final cConfig = config.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.loadWallet(cConfig),
              ptrsToFree: [cConfig],
            );
            break;
          case "startsync":
            final name = args["name"] ?? "";
            final peers = args["peers"] ?? "";
            final cName = name.toCString();
            final cPeers = peers.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.syncWallet(cName, cPeers),
              ptrsToFree: [cName, cPeers],
            );
            break;
          case "closewallet":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.closeWallet(cName),
              ptrsToFree: [cName],
            );
            break;
          case "changewalletpassword":
            final name = args["name"] ?? "";
            final oldPass = args["oldpass"] ?? "";
            final newPass = args["newpass"] ?? "";
            final cName = name.toCString();
            final cOldPass = oldPass.toCString();
            final cNewPass = newPass.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.changePassphrase(cName, cOldPass, cNewPass),
              ptrsToFree: [cName, cOldPass, cNewPass],
            );
            break;
          case "walletseed":
            final name = args["name"] ?? "";
            final pass = args["pass"] ?? "";
            final cName = name.toCString();
            final cPass = pass.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.walletSeed(cName, cPass),
              ptrsToFree: [cName, cPass],
            );
            break;
          case "syncstatus":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.syncWalletStatus(cName),
              ptrsToFree: [cName],
            );
            break;
          case "balance":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.walletBalance(cName),
              ptrsToFree: [cName],
            );
            break;
          case "estimatefee":
            final name = args["name"] ?? "";
            final numBlocks = args["numblocks"] ?? "";
            final cName = name.toCString();
            final cNumBlocks = numBlocks.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.estimateFee(cName, cNumBlocks),
              ptrsToFree: [cName, cNumBlocks],
            );
            break;
          case "createtransaction":
            final name = args["name"] ?? "";
            final signReq = args["signreq"] ?? "";
            final cName = name.toCString();
            final cSignReq = signReq.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.createTransaction(cName, cSignReq),
              ptrsToFree: [cName, cSignReq],
            );
            break;
          case "sendrawtransaction":
            final name = args["name"] ?? "";
            final txHex = args["txhex"] ?? "";
            final cName = name.toCString();
            final cTxHex = txHex.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.sendRawTransaction(cName, cTxHex),
              ptrsToFree: [cName, cTxHex],
            );
            break;
          case "listtransactions":
            final name = args["name"] ?? "";
            final from = args["from"] ?? "";
            final count = args["count"] ?? "";
            final cName = name.toCString();
            final cFrom = from.toCString();
            final cCount = count.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.listTransactions(cName, cFrom, cCount),
              ptrsToFree: [cName, cFrom, cCount],
            );
            break;
          case "bestblock":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.bestBlock(cName),
              ptrsToFree: [cName],
            );
            break;
          case "listunspents":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.listUnspents(cName),
              ptrsToFree: [cName],
            );
            break;
          case "rescanfromheight":
            final name = args["name"] ?? "";
            final height = args["height"] ?? "";
            final cName = name.toCString();
            final cHeight = height.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.rescanFromHeight(cName, cHeight),
              ptrsToFree: [cName, cHeight],
            );
            break;
          case "signmessage":
            final name = args["name"] ?? "";
            final message = args["message"] ?? "";
            final address = args["address"] ?? "";
            final pass = args["pass"] ?? "";
            final cName = name.toCString();
            final cMessage = message.toCString();
            final cAddress = address.toCString();
            final cPass = pass.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.signMessage(cName, cMessage, cAddress, cPass),
              ptrsToFree: [cName, cMessage, cAddress, cPass],
            );
            break;
          case "verifymessage":
            final name = args["name"] ?? "";
            final message = args["message"] ?? "";
            final address = args["address"] ?? "";
            final sig = args["sig"] ?? "";
            final cName = name.toCString();
            final cMessage = message.toCString();
            final cAddress = address.toCString();
            final cSig = sig.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.verifyMessage(cName, cMessage, cAddress, cSig),
              ptrsToFree: [cName, cMessage, cAddress, cSig],
            );
            break;
          case "newexternaladdress":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.newExternalAddress(cName),
              ptrsToFree: [cName],
              skipErrorCheck: true,
            );
            break;
          case "defaultpubkey":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.defaultPubkey(cName),
              ptrsToFree: [cName],
            );
            break;
          case "addresses":
            final name = args["name"] ?? "";
            final nUsed = args["nused"] ?? "";
            final nUnused = args["nunused"] ?? "";
            final cName = name.toCString();
            final cNUsed = nUsed.toCString();
            final cNUnused = nUnused.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.addresses(cName, cNUsed, cNUnused),
              ptrsToFree: [cName, cNUsed, cNUnused],
            );
            break;
          case "birthstate":
            final name = args["name"] ?? "";
            final cName = name.toCString();
            res = executePayloadFn(
              fn: () => dcrwalletApi.birthState(cName),
              ptrsToFree: [cName],
            );
            break;
          case "shutdown":
            final name = args["name"] ?? "";
            // final cName = name.toCString();
            executePayloadFn(
              fn: () => dcrwalletApi.shutdown(),
              ptrsToFree: [],
            );
            break;
          default:
            res = PayloadResult("", "unknown libwallet method ${method}", 0);
        }
        sendPort.send((id, res));
      } catch (e) {
        final errMsg = e.toString();
        printV("decred libwallet returned an error for method ${method}: ${errMsg}");
        sendPort.send((id, PayloadResult("", errMsg, 0)));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  // initLibdcrwallet initializes libdcrwallet using the provided logDir and gets
  // it ready for use. This must be done before attempting to create, load or use
  // a wallet. An empty string can be used to log to stdout and create no log files.
  Future<void> initLibdcrwallet(String logDir, String level) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "initlibdcrwallet",
      "logdir": logDir,
      "level": level,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<void> createWallet(String config) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "createwallet",
      "config": config,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<void> createWatchOnlyWallet(String config) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "createwatchonlywallet",
      "config": config,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<void> loadWallet(String config) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "loadwallet",
      "config": config,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<void> startSync(String walletName, String peers) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "startsync",
      "name": walletName,
      "peers": peers,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<void> closeWallet(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "closewallet",
      "name": walletName,
    };
    _commands.send((id, req));
    await completer.future;
  }

  Future<String> changeWalletPassword(
      String walletName, String currentPassword, String newPassword) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "changewalletpassword",
      "name": walletName,
      "oldpass": currentPassword,
      "newpass": newPassword
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String?> walletSeed(String walletName, String walletPassword) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "walletseed",
      "name": walletName,
      "pass": walletPassword,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> syncStatus(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "syncstatus",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<Map> balance(String walletName, {bool throwOnError = false}) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "balance",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    try {
      return jsonDecode(res.payload);
    } catch (_) {
      if (throwOnError) {
        rethrow;
      }
      return {};
    }
  }

  Future<String> estimateFee(String walletName, int numBlocks) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "estimatefee",
      "name": walletName,
      "numblocks": numBlocks.toString(),
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> createTransaction(
      String walletName, String createTransactionReq) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "createtransaction",
      "name": walletName,
      "signreq": createTransactionReq,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> sendRawTransaction(String walletName, String txHex) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "sendrawtransaction",
      "name": walletName,
      "txhex": txHex,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> listTransactions(String walletName, String from, String count) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "listtransactions",
      "name": walletName,
      "from": from,
      "count": count,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> bestBlock(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "bestblock",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> listUnspents(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "listunspents",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> rescanFromHeight(String walletName, String height) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "rescanfromheight",
      "name": walletName,
      "height": height,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> signMessage(
      String walletName, String message, String address, String walletPass) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "signmessage",
      "name": walletName,
      "message": message,
      "address": address,
      "pass": walletPass,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> verifyMessage(
      String walletName, String message, String address, String sig) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "verifymessage",
      "name": walletName,
      "message": message,
      "address": address,
      "sig": sig,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String?> newExternalAddress(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "newexternaladdress",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    if (res.errCode == ErrCodeNotSynced) {
      // Wallet is not synced. We do not want to give out a used address so give
      // nothing.
      return null;
    }
    checkErr(res.err);
    return res.payload;
  }

  Future<String> defaultPubkey(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "defaultpubkey",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> addresses(String walletName, String nUsed, String nUnused) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "addresses",
      "name": walletName,
      "nused": nUsed,
      "nunused": nUnused,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<String> birthState(String walletName) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "birthstate",
      "name": walletName,
    };
    _commands.send((id, req));
    final res = await completer.future as PayloadResult;
    return res.payload;
  }

  Future<void> shutdown() async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    final req = {
      "method": "shutdown",
    };
    _commands.send((id, req));
    await completer.future as PayloadResult;
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
    }
  }
}
