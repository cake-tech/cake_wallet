import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_mweb/mweb_ffi.dart';
import 'package:cw_mweb/print_verbose.dart';
import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static RpcClient? _rpcClient;
  static ClientChannel? _clientChannel;
  static int? _port;
  static const TIMEOUT_DURATION = Duration(seconds: 15);
  static Timer? logTimer;
  static String? nodeUriOverride;


  static Future<void> setNodeUriOverride(String uri) async {
    nodeUriOverride = uri;
    if (_rpcClient != null) {
      await stop();
      // will be re-started automatically when the next rpc call is made
    }
  }

  static void readFileWithTimer(String filePath) {
    final file = File(filePath);
    int lastLength = 0;

    logTimer?.cancel();
    logTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final currentLength = await file.length();

        if (currentLength != lastLength) {
          final fileStream = file.openRead(lastLength, currentLength);
          final newLines = await fileStream.transform(utf8.decoder).join();
          lastLength = currentLength;
          printV(newLines);
        }
      } on GrpcError catch (e) {
        printV('Caught grpc error: ${e.message}');
      } catch (e) {
        printV('The mwebd debug log probably is not initialized yet.');
      }
    });
  }

  static Future<void> _initializeClient() async {
    printV("_initializeClient() called!");
    final appDir = await getApplicationSupportDirectory();
    const ltcNodeUri = "ltc-electrum.cakewallet.com:9333";

    String debugLogPath = "${appDir.path}/logs/debug.log";
    readFileWithTimer(debugLogPath);

    _port = MWebFfi.instance.start(appDir.path, nodeUriOverride ?? ltcNodeUri);
    if (_port == null || _port == 0) {
      throw Exception("Failed to start server");
    }
    printV("Attempting to connect to server on port: $_port");

    _clientChannel = ClientChannel('127.0.0.1', port: _port!, channelShutdownHandler: () {
      _rpcClient = null;
      printV("Channel is shutting down!");
    },
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          keepAlive: ClientKeepAliveOptions(permitWithoutCalls: true),
        ));
    _rpcClient = RpcClient(_clientChannel!);
  }

  static Future<RpcClient> stub({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        if (_rpcClient == null) {
          await _initializeClient();
        }
        final status = await _rpcClient!
            .status(StatusRequest(), options: CallOptions(timeout: TIMEOUT_DURATION));
        if (status.blockTime == 0) {
          throw Exception("blockTime shouldn't be 0! (this connection is likely broken)");
        }
        return _rpcClient!;
      } on GrpcError catch (e) {
        printV("Attempt $i failed: $e");
        printV('Caught grpc error: ${e.message}');
        _rpcClient = null;
        // necessary if the database isn't open:
        await stop();
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        printV("Attempt $i failed: $e");
        _rpcClient = null;
        await stop();
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    throw Exception("Failed to connect after $maxRetries attempts");
  }

  static Future<void> stop() async {
    try {
      MWebFfi.instance.stop();
      await cleanup();
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error stopping server: $e");
    }
  }

  static String? address(Uint8List scanSecret, Uint8List spendPub, int index) {
    try {
      return MWebFfi.instance.addresses(scanSecret, spendPub, index, index + 1).split(',').first;
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting address: $e");
    }
    return null;
  }

  static List<String>? addresses(
      Uint8List scanSecret, Uint8List spendPub, int fromIndex, int toIndex) {
    try {
      return MWebFfi.instance.addresses(scanSecret, spendPub, fromIndex, toIndex).split(',');
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting addresses: $e");
    }
    return null;
  }

  static Future<void> cleanup() async {
    try {
      await _clientChannel?.terminate();
    } catch (_) {}
    _rpcClient = null;
    _clientChannel = null;
    _port = null;
  }

  // wrappers that handle the connection issues:
  static Future<SpentResponse> spent(SpentRequest request) async {
    log("mweb.spent() called");
    try {
      _rpcClient = await stub();
      return await _rpcClient!.spent(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting spent: $e");
    }
    return SpentResponse();
  }

  static Future<StatusResponse> status(StatusRequest request) async {
    log("mweb.status() called");
    try {
      _rpcClient = await stub();
      return await _rpcClient!.status(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting status: $e");
    }
    return StatusResponse();
  }

  static Future<CreateResponse> create(CreateRequest request) async {
    log("mweb.create() called");
    try {
      _rpcClient = await stub();
      return await _rpcClient!.create(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting create: $e");
    }
    return CreateResponse();
  }

  static Future<ResponseStream<Utxo>?> utxos(UtxosRequest request) async {
    log("mweb.utxos() called");
    try {
      _rpcClient = await stub();
      final resp = _rpcClient!
          .utxos(request, options: CallOptions(timeout: const Duration(days: 1000 * 365)));
      log("got utxo stream");
      return resp;
    } on GrpcError catch (e) {
      printV('Caught grpc error: ${e.message}');
    } catch (e) {
      printV("Error getting utxos: $e");
    }
    return null;
  }

  static Future<BroadcastResponse> broadcast(BroadcastRequest request) async {
    log("mweb.broadcast() called");
    try {
      _rpcClient = await stub();
      return await _rpcClient!.broadcast(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } on GrpcError catch (e) {
      log('Caught grpc error: ${e.message}');
      throw "error from broadcast mweb: $e";
    } catch (e) {
      printV("Error getting utxos: $e");
      rethrow;
    }
  }

  static Future<PsbtResponse> psbtCreate(PsbtCreateRequest request) async {
    log("mweb.psbtCreate() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtCreate(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }

  static Future<PsbtResponse> psbtAddInput(PsbtAddInputRequest request) async {
    log("mweb.psbtAddInput() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtAddInput(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }

  static Future<PsbtResponse> psbtAddRecipient(PsbtAddRecipientRequest request) async {
    log("mweb.psbtAddRecipient() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtAddRecipient(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }

  static Future<PsbtGetRecipientsResponse> psbtGetRecipients(PsbtGetRecipientsRequest request) async {
    log("mweb.psbtGetRecipients() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtGetRecipients(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }

  static Future<CreateResponse> psbtExtract(PsbtExtractRequest request) async {
    log("mweb.psbtExtract() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtExtract(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }
  static Future<PsbtResponse> psbtSign(PsbtSignRequest request) async {
    printV("mweb.psbtSign() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtSign(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }

  static Future<PsbtResponse> psbtSignNonMweb(PsbtSignNonMwebRequest request) async {
    printV("mweb.psbtSignNonMweb() called");
    _rpcClient = await stub();
    return await _rpcClient!.psbtSignNonMweb(request, options: CallOptions(timeout: TIMEOUT_DURATION));
  }
}
