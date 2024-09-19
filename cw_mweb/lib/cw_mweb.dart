import 'dart:typed_data';

import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static RpcClient? _rpcClient;
  static ClientChannel? _clientChannel;
  static int? _port;
  static const TIMEOUT_DURATION = Duration(seconds: 5);

  static Future<void> _initializeClient() async {
    await stop();
    // wait a few seconds to make sure the server is stopped
    await Future.delayed(const Duration(seconds: 5));

    final appDir = await getApplicationSupportDirectory();
    _port = await CwMwebPlatform.instance.start(appDir.path);
    if (_port == null || _port == 0) {
      throw Exception("Failed to start server");
    }
    print("Attempting to connect to server on port: $_port");

    // wait for the server to finish starting up before we try to connect to it:
    await Future.delayed(const Duration(seconds: 5));

    _clientChannel = ClientChannel('127.0.0.1', port: _port!, channelShutdownHandler: () {
      print("Channel shutdown!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
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
      } catch (e) {
        print("Attempt $i failed: $e");
        _rpcClient = null;
      }
    }
    throw Exception("Failed to connect after $maxRetries attempts");
  }

  static Future<void> stop() async {
    try {
      await CwMwebPlatform.instance.stop();
      await cleanup();
    } catch (e) {
      print("Error stopping server: $e");
    }
  }

  static Future<String?> address(Uint8List scanSecret, Uint8List spendPub, int index) async {
    try {
      return CwMwebPlatform.instance.address(scanSecret, spendPub, index);
    } catch (e) {
      print("Error getting address: $e");
      return null;
    }
  }

  static Future<void> cleanup() async {
    await _clientChannel?.terminate();
    _rpcClient = null;
    _clientChannel = null;
    _port = null;
  }

  // wrappers that handle the connection issues:
  static Future<SpentResponse> spent(SpentRequest request) async {
    try {
      if (_rpcClient == null) {
        await _initializeClient();
      }
      return await _rpcClient!.spent(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } catch (e) {
      print("Error getting spent: $e");
      return SpentResponse();
    }
  }

  static Future<StatusResponse> status(StatusRequest request) async {
    try {
      if (_rpcClient == null) {
        await _initializeClient();
      }
      return await _rpcClient!.status(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } catch (e) {
      print("Error getting status: $e");
      return StatusResponse();
    }
  }

  static Future<CreateResponse> create(CreateRequest request) async {
    try {
      if (_rpcClient == null) {
        await _initializeClient();
      }
      return await _rpcClient!.create(request, options: CallOptions(timeout: TIMEOUT_DURATION));
    } catch (e) {
      print("Error getting create: $e");
      return CreateResponse();
    }
  }

  static Future<ResponseStream<Utxo>?> utxos(UtxosRequest request) async {
    try {
      if (_rpcClient == null) {
        await _initializeClient();
      }
      // this is a stream, so we should have an effectively infinite timeout:
      return _rpcClient!.utxos(request, options: CallOptions(timeout: const Duration(days: 99)));
    } catch (e) {
      print("Error getting utxos: $e");
      return null;
    }
  }
}
