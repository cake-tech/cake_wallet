import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// posts app changelog to testflight using appstore connect api
// mostly for use in ios ci, you can see how it's called there.
// dart: only, no packages - runs on a bare linux checkout with no pub get,
// which is how the wait for apple stays off the macos runner.

final String _api = Platform.environment["ASC_API_BASE"] ?? "https://api.appstoreconnect.apple.com";

const _locale = "en-US";
const _whatsNewLimit = 4000;
const _pollInterval = Duration(seconds: 15);
const _maxAttempts = 4;
const _tokenLifetime = Duration(minutes: 15);
const _tokenMargin = Duration(minutes: 2);

final Duration _pollTimeout =
    Duration(seconds: int.tryParse(Platform.environment["ASC_POLL_TIMEOUT"] ?? "") ?? 1000);

const _requestTimeout = Duration(seconds: 60);

final _client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

class _ApiException implements Exception {
  _ApiException(this.status, this.body);

  final int status;
  final String body;

  @override
  String toString() => "HTTP $status\n$body";
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

String _env(String name) => Platform.environment[name]!;

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll("=", "");

Uint8List _derToRaw(Uint8List der, {int size = 32}) {
  if (der[0] != 0x30) {
    throw const FormatException("signature is not a DER sequence");
  }
  if (der[1] & 0x80 != 0) {
    throw const FormatException("unexpected long-form DER length");
  }
  final out = BytesBuilder();
  var i = 2;
  for (var member = 0; member < 2; member++) {
    if (der[i] != 0x02) {
      throw const FormatException("signature member is not a DER integer");
    }
    final length = der[i + 1];
    var value = der.sublist(i + 2, i + 2 + length);
    i += 2 + length;
    var start = 0;
    while (start < value.length - 1 && value[start] == 0) {
      start++;
    }
    value = value.sublist(start);
    if (value.length > size) {
      throw const FormatException("signature member is too large for P-256");
    }
    out.add(Uint8List(size - value.length)); // left pad
    out.add(value);
  }
  return out.takeBytes();
}

Future<Uint8List> _sign(List<int> input, String keyPath) async {
  final process = await Process.start("openssl", ["dgst", "-sha256", "-sign", keyPath]);
  final stdoutBytes = process.stdout.fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d));
  final stderrText = systemEncoding.decodeStream(process.stderr);
  process.stdin.add(input);
  await process.stdin.close();
  if (await process.exitCode != 0) {
    _fail("openssl could not sign with $keyPath: ${(await stderrText).trim()}");
  }
  return (await stdoutBytes).takeBytes();
}

String? _jwt;
DateTime _jwtExpiry = DateTime.fromMillisecondsSinceEpoch(0);

// generates jwt from our
Future<String> _token() async {
  final now = DateTime.now();
  final cached = _jwt;
  if (cached != null && now.isBefore(_jwtExpiry.subtract(_tokenMargin))) {
    return cached;
  }

  final expiry = now.add(_tokenLifetime);
  final header = {"alg": "ES256", "kid": _env("ASC_KEY_ID"), "typ": "JWT"};
  final claims = {
    "iss": _env("ASC_ISSUER_ID"),
    "iat": now.millisecondsSinceEpoch ~/ 1000,
    "exp": expiry.millisecondsSinceEpoch ~/ 1000,
    "aud": "appstoreconnect-v1",
  };
  final signingInput = utf8.encode(
    "${_b64(utf8.encode(json.encode(header)))}.${_b64(utf8.encode(json.encode(claims)))}",
  );

  final signature = _derToRaw(await _sign(signingInput, _env("ASC_KEY_PATH")));
  _jwt = "${utf8.decode(signingInput)}.${_b64(signature)}";
  _jwtExpiry = expiry;
  return _jwt!;
}

bool _isTransient(Object error) {
  if (error is _ApiException) {
    return error.status >= 500 || error.status == 429;
  }
  return error is SocketException || error is TimeoutException || error is HttpException;
}

Future<T> _withRetry<T>(String what, Future<T> Function() operation) async {
  for (var attempt = 1;; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt >= _maxAttempts || !_isTransient(error)) {
        rethrow;
      }
      final wait = Duration(seconds: 5 * attempt);
      print("  $what failed (attempt $attempt/$_maxAttempts): $error");
      print("  retrying in ${wait.inSeconds}s");
      await Future.delayed(wait);
    }
  }
}

Future<Map<String, dynamic>> _send(String method, Uri uri, Map<String, dynamic>? body) async {
  final request = await _client.openUrl(method, uri);
  // minted per attempt, so a long backoff cannot send one that expired waiting
  request.headers.set(HttpHeaders.authorizationHeader, "Bearer ${await _token()}");
  if (body != null) {
    final payload = utf8.encode(json.encode(body));
    request.headers.contentType = ContentType.json;
    // without this dart sends the body chunked, which not every server accepts
    request.contentLength = payload.length;
    request.add(payload);
  }

  final response = await request.close().timeout(_requestTimeout);
  final text = await utf8.decodeStream(response).timeout(_requestTimeout);
  if (response.statusCode >= 300) {
    throw _ApiException(response.statusCode, text);
  }
  return text.isEmpty ? <String, dynamic>{} : json.decode(text) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _call(String method, Uri uri, {Map<String, dynamic>? body}) async {
  try {
    return await _withRetry("$method ${uri.path}", () => _send(method, uri, body));
  } catch (error) {
    _fail("$method $uri\n$error");
  }
}

Future<void> main() async {
  final bundleId = _env("IOS_BUNDLE_ID");
  final buildNumber = _env("BUILD_NUMBER");

  final message = (await utf8.decodeStream(stdin)).trim();
  final whatsNew = message.length > _whatsNewLimit ? message.substring(0, _whatsNewLimit) : message;

  final apps = await _call(
    "GET",
    Uri.parse("$_api/v1/apps").replace(queryParameters: {"filter[bundleId]": bundleId}),
  );
  final matches = apps["data"] as List<dynamic>;
  final appId = matches.first["id"] as String;

  final filters = {
    "filter[app]": appId,
    "filter[version]": buildNumber,
    "sort": "-uploadedDate",
    "limit": "1",
  };
  final appVersion = Platform.environment["APP_VERSION"];
  if (appVersion != null && appVersion.isNotEmpty) {
    filters["filter[preReleaseVersion.version]"] = appVersion;
  }
  final buildsUri = Uri.parse("$_api/v1/builds").replace(queryParameters: filters);

  final deadline = DateTime.now().add(_pollTimeout);
  String buildId;
  while (true) {
    final builds = await _call("GET", buildsUri);
    final found = builds["data"] as List<dynamic>;
    if (found.isNotEmpty) {
      buildId = found.first["id"] as String;
      break;
    }
    if (!DateTime.now().isBefore(deadline)) {
      _fail("build $buildNumber never appeared in App Store Connect within "
          "${_pollTimeout.inSeconds}s.\nThe upload itself succeeded - only the changelog is "
          "missing; you can paste it into TestFlight by hand.");
    }
    print("waiting for App Store Connect to register build $buildNumber");
    await Future.delayed(_pollInterval);
  }

  print("build $buildNumber is $buildId");

  // Apple creates an empty localization on its own once processing starts, so
  // this has to update in place as often as it creates.
  final existing = await _call(
    "GET",
    Uri.parse("$_api/v1/builds/$buildId/betaBuildLocalizations"),
  );
  final mine = (existing["data"] as List<dynamic>)
      .where((localization) => localization["attributes"]["locale"] == _locale)
      .toList();

  if (mine.isNotEmpty) {
    final id = mine.first["id"] as String;
    await _call(
      "PATCH",
      Uri.parse("$_api/v1/betaBuildLocalizations/$id"),
      body: {
        "data": {
          "type": "betaBuildLocalizations",
          "id": id,
          "attributes": {"whatsNew": whatsNew},
        },
      },
    );
  } else {
    await _call(
      "POST",
      Uri.parse("$_api/v1/betaBuildLocalizations"),
      body: {
        "data": {
          "type": "betaBuildLocalizations",
          "attributes": {"locale": _locale, "whatsNew": whatsNew},
          "relationships": {
            "build": {
              "data": {"type": "builds", "id": buildId},
            },
          },
        },
      },
    );
  }

  _client.close(); // a kept-alive connection would hold the vm open

  print("changelog set:");
  print(whatsNew.split("\n").map((line) => "  $line").join("\n"));
}
