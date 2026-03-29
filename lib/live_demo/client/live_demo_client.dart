


import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class SyncData {
  int serverTimeMs;
  int positionMs;
  SyncData(this.serverTimeMs, this.positionMs);
}

class LiveDemoClient {
  Socket? _client;
  final BytesBuilder _buffer = BytesBuilder();

  Future<void> connect(String host, int port) async {
    _client = await Socket.connect(host, port);
  }

  Future<Map<String, dynamic>> getConfig() async {
    await _send({"type": "get_config"});
    final header = await _readFrame();

    if (header["type"] != "config_data") {
      throw Exception("Expected config_data");
    }

    final size = header["size"] as int;
    final bytes = await _readExact(size);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<void> _downloadVideo() async {
    await _send({"type": "get_video"});
    final header = await _readFrame();

    if (header["type"] != "video_data") {
      throw Exception("Expected video_data");
    }

    final size = header["size"] as int;

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/video.mp4.tmp");
    final sink = file.openWrite();

    int remaining = size;

    while (remaining > 0) {
      final chunkSize = remaining > 65536 ? 65536 : remaining;
      final chunk = await _readExact(chunkSize);
      sink.add(chunk);
      remaining -= chunk.length;
    }

    await sink.flush();
    await sink.close();

    final finalFile = File("${dir.path}/video.mp4");
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await file.rename(finalFile.path);
  }


  Future<void> ensureVideoInitialized() async {
    await _send({"type": "status"});
    final status = await _readFrame();

    if (status["type"] != "status_response") {
      throw Exception("Expected status_response");
    }

    final remoteHash = status["video_hash"] as String;
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/video.mp4");

    String? localHash;
    if (await file.exists()) {
      final digest = await sha256.bind(file.openRead()).first;
      localHash = digest.toString();
    }

    if (localHash != remoteHash) {
      await _downloadVideo();
    }
  }

  Future<SyncData> getSync() async {
    await _send({"type": "get_sync"});
    final msg = await _readFrame();

    if (msg["type"] != "sync_response") {
      throw Exception("Expected sync_response");
    }

    return SyncData(
      msg["server_time_ms"] as int,
      msg["position_ms"] as int,
    );
  }

  Future<void> _send(Map<String, dynamic> obj) async {
    final socket = _client;
    if (socket == null) throw Exception("Not connected");

    final data = utf8.encode(jsonEncode(obj));
    final header = ByteData(4)..setUint32(0, data.length, Endian.big);

    socket.add(header.buffer.asUint8List());
    socket.add(data);
    await socket.flush();
  }

  Future<Map<String, dynamic>> _readFrame() async {
    final headerBytes = await _readExact(4);
    final length = ByteData.sublistView(headerBytes).getUint32(0, Endian.big);
    final payload = await _readExact(length);
    return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
  }

  Future<Uint8List> _readExact(int count) async {
    if (_client == null) throw Exception("not connected");

    while (_buffer.length < count) {
      final chunk = await _client!.first;
      _buffer.add(chunk);
    }

    final all = _buffer.toBytes();
    final out = Uint8List.sublistView(all, 0, count);
    final remaining = all.sublist(count);

    _buffer.clear();
    _buffer.add(remaining);

    return Uint8List.fromList(out);
  }

  Future<void> close() async {
    await _client?.flush();
    await _client?.close();
    _client = null;
    _buffer.clear();
  }
}