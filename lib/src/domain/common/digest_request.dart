import 'dart:convert';
import 'package:dio/dio.dart' as Dio;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:math' as math;

class DigestRequest {
  final md5 = crypto.md5;

  String generateCnonce() {
    final rnd = math.Random.secure();
    var values = List<int>.generate(32, (i) => rnd.nextInt(256));
    return base64Url.encode(values).substring(0, 8);
  }

  String generateHA1({String realm, String username, String password}) {
    final ha1CredentialsData =
    Utf8Encoder().convert('$username:$realm:$password');
    final ha1 = md5.convert(ha1CredentialsData).toString();

    return ha1;
  }

  String generateHA2({String method, String uri}) {
    final ha2Data = Utf8Encoder().convert('$method:$uri');
    final ha2 = md5.convert(ha2Data).toString();

    return ha2;
  }

  String generateResponseString(
      {String ha1,
        String ha2,
        String nonce,
        String nonceCount,
        String cnonce,
        String qop}) {
    final responseData =
    Utf8Encoder().convert('$ha1:$nonce:$nonceCount:$cnonce:$qop:$ha2');
    final response = md5.convert(responseData).toString();

    return response;
  }

  Map<String, String> parsetAuthorizationHeader({String source}) {
    final authHeaderParts =
    source.substring(7).split(',').map((item) => item.trim());
    var authenticate = Map<String, String>();

    for (final part in authHeaderParts) {
      final kv = part.split('=');
      authenticate[kv[0]] =
          kv.getRange(1, kv.length).join('=').replaceAll('"', '');
    }

    return authenticate;
  }

  Future<Dio.Response> request(
      {String uri, String login, String password}) async {
    final path = '/json_rpc';
    final method = 'POST';
    final url = Uri.http(uri, path);
    final dio = Dio.Dio();

    Map<String, String> headers = {'Content-type': 'application/json'};
    String body =
    json.encode({"jsonrpc": "2.0", "id": "0", "method": "get_info"});

    var credentialsResponse = await dio.post(url.toString(),
        options: Dio.Options(headers: headers, validateStatus: (_) => true));
    var resHeaeders = credentialsResponse.headers;
    final authenticate =
    parsetAuthorizationHeader(source: resHeaeders['www-authenticate'].first);
    final qop = authenticate['qop'];
    final algorithm = 'MD5';
    final realm = 'monero-rpc';
    final nonce = authenticate['nonce'];
    final cnonce = generateCnonce();

    var nonceCount = '00000001';

    final ha1 = generateHA1(realm: realm, username: login, password: password);
    final ha2 = generateHA2(method: method, uri: path);
    final response = generateResponseString(
        ha1: ha1,
        ha2: ha2,
        nonce: nonce,
        nonceCount: nonceCount,
        cnonce: cnonce,
        qop: qop);

    final authorizationHeaders = {
      'Content-type': 'application/json',
      'Authorization':
      'Digest username="$login",realm="$realm",nonce="$nonce",uri="$path",algorithm="$algorithm",qop=$qop,nc=$nonceCount,cnonce="$cnonce",response="$response"'
    };

    final res = await dio.post(url.toString(),
        options: Dio.Options(headers: authorizationHeaders), data: body);
    return res;
  }
}