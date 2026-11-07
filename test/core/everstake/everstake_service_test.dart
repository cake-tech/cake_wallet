import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cake_wallet/core/everstake/everstake_service.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeHttpClient extends Fake implements HttpClient {
  _FakeHttpClient(this.body);

  final String body;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeRequest(body);

  @override
  void close({bool force = false}) {}
}

class _FakeRequest extends Fake implements HttpClientRequest {
  _FakeRequest(this.body);

  final String body;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(body);
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _FakeResponse extends StreamView<List<int>> implements HttpClientResponse {
  _FakeResponse(String body) : super(Stream.value(utf8.encode(body)));

  @override
  int get statusCode => 200;

  @override
  int get contentLength => -1;

  @override
  HttpHeaders get headers => _FakeHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => "OK";

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test("parses an instant withdrawal whose double has more decimals than ETH", () async {
    final originalTor = CakeTor.instance;
    addTearDown(() => CakeTor.instance = originalTor);
    CakeTor.instance = CakeTorDisabled();

    final instant = await HttpOverrides.runZoned(
      () => EverstakeService().simulateEthereumUnstake(
        address: "0x15273714bdfed50e922c4cdd35ed50291780b392",
        amount: Money.parse("0.01", CryptoCurrency.eth),
        allowedInterchangeNum: 5,
      ),
      createHttpClient: (_) => _FakeHttpClient("{\"result\": 0.0012345678901234567}"),
    );

    expect(instant, Money.parse("0.001234567890123457", CryptoCurrency.eth));
  });
}
