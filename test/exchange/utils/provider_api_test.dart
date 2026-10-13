import "dart:convert";

import "package:cake_wallet/exchange/utils/provider_api.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart";

class _Call {
  const _Call(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class _RecordingProxy implements ProxyWrapper {
  _RecordingProxy(this.response);

  final Response response;
  final List<_Call> calls = [];

  @override
  Future<Response> get({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) async {
    calls.add(_Call("GET", clearnetUri!, headers ?? {}, null));
    return response;
  }

  @override
  Future<Response> post({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
    bool allowMitmMoneroBypassSSLCheck = false,
  }) async {
    calls.add(_Call("POST", clearnetUri!, headers ?? {}, body));
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not faked");
}

class _GetThing extends ApiRequest<Map<String, dynamic>> {
  const _GetThing(this.query);

  final Map<String, dynamic> query;

  @override
  String path() => "/v1/thing";

  @override
  Map<String, dynamic> toJson() => query;

  @override
  Map<String, dynamic> decode(Object json) => json as Map<String, dynamic>;
}

class _PostThing extends ApiRequest<List<dynamic>> {
  const _PostThing(this.payload) : super.post();

  final Map<String, dynamic> payload;

  @override
  String path() => "/v1/things";

  @override
  Map<String, dynamic> toJson() => payload;

  @override
  List<dynamic> decode(Object json) => json as List<dynamic>;
}

void main() {
  ProviderApi api(
    _RecordingProxy proxy, {
    String? Function(Map<String, dynamic> json)? errorMessage,
  }) => ProviderApi(
    proxy,
    authority: "api.example.com",
    headers: {"x-api-key": "key"},
    errorMessage: errorMessage,
  );

  group("send", () {
    test("a get puts the request's json in the query and decodes the body", () async {
      final proxy = _RecordingProxy(Response('{"ok":true}', 200));

      final result = await api(proxy).send(const _GetThing({"from": "btc", "to": "xmr"}));

      expect(result, {"ok": true});
      expect(proxy.calls.single.method, "GET");
      expect(proxy.calls.single.uri, Uri.https("api.example.com", "/v1/thing", {"from": "btc", "to": "xmr"}));
      expect(proxy.calls.single.headers, {"x-api-key": "key"});
      expect(proxy.calls.single.body, isNull);
    });

    test("a post sends the request's json as the body, not in the query", () async {
      final proxy = _RecordingProxy(Response("[1,2]", 200));

      final result = await api(proxy).send(const _PostThing({"amount": "2", "fixed": true}));

      expect(result, [1, 2]);
      expect(proxy.calls.single.method, "POST");
      expect(proxy.calls.single.uri, Uri.https("api.example.com", "/v1/things"));
      expect(json.decode(proxy.calls.single.body!), {"amount": "2", "fixed": true});
    });

    test("a post adds a json content type on top of the provider's headers", () async {
      final proxy = _RecordingProxy(Response("[]", 200));

      await api(proxy).send(const _PostThing({}));

      expect(proxy.calls.single.headers, {"x-api-key": "key", "Content-Type": "application/json"});
    });

    test("any 2xx is a success", () async {
      for (final status in [200, 201, 299]) {
        final proxy = _RecordingProxy(Response('{"status":$status}', status));

        expect(await api(proxy).send(const _GetThing({})), {"status": status}, reason: "$status");
      }
    });
  });

  group("errors", () {
    test("a non 2xx answer throws with the status, body and decoded json", () async {
      const body = '{"error":"not_found","message":"no such trade"}';
      final proxy = _RecordingProxy(Response(body, 404));

      await expectLater(
        api(proxy).send(const _GetThing({})),
        throwsA(
          isA<ProviderHttpException>()
              .having((e) => e.statusCode, "statusCode", 404)
              .having((e) => e.body, "body", body)
              .having((e) => e.json, "json", {"error": "not_found", "message": "no such trade"}),
        ),
      );
    });

    test("the provider's error message reader names the error", () async {
      final proxy = _RecordingProxy(Response('{"message":"amount too low"}', 400));

      await expectLater(
        api(proxy, errorMessage: (json) => json["message"]?.toString()).send(const _GetThing({})),
        throwsA(
          isA<ProviderHttpException>()
              .having((e) => e.message, "message", "amount too low")
              .having((e) => e.toString(), "toString", "amount too low"),
        ),
      );
    });

    test("without a readable message the status and body are used", () async {
      const body = '{"something":"else"}';
      final proxy = _RecordingProxy(Response(body, 400));

      await expectLater(
        api(proxy, errorMessage: (json) => json["message"]?.toString()).send(const _GetThing({})),
        throwsA(isA<ProviderHttpException>().having((e) => e.message, "message", "HTTP 400: $body")),
      );
    });

    test("an error body that is not a json object skips the message reader", () async {
      var readerCalled = false;
      final proxy = _RecordingProxy(Response('["nope"]', 500));

      await expectLater(
        api(proxy, errorMessage: (json) {
          readerCalled = true;
          return "should not be used";
        }).send(const _GetThing({})),
        throwsA(
          isA<ProviderHttpException>()
              .having((e) => e.message, "message", 'HTTP 500: ["nope"]')
              .having((e) => e.json, "json", ["nope"]),
        ),
      );
      expect(readerCalled, isFalse);
    });

    test("an error body that is not json at all keeps just the status", () async {
      final proxy = _RecordingProxy(Response("<html>bad gateway</html>", 502));

      await expectLater(
        api(proxy).send(const _GetThing({})),
        throwsA(
          isA<ProviderHttpException>()
              .having((e) => e.message, "message", "HTTP 502")
              .having((e) => e.json, "json", isNull)
              .having((e) => e.body, "body", "<html>bad gateway</html>"),
        ),
      );
    });

    test("3xx is not a success", () async {
      final proxy = _RecordingProxy(Response("{}", 302));

      await expectLater(
        api(proxy).send(const _GetThing({})),
        throwsA(isA<ProviderHttpException>().having((e) => e.statusCode, "statusCode", 302)),
      );
    });

    test("mapError replaces the http error with the caller's exception", () async {
      final proxy = _RecordingProxy(Response('{"error":"not_found"}', 404));
      final notFound = Exception("trade not found");

      await expectLater(
        api(proxy).send(
          const _GetThing({}),
          mapError: (e) => e.statusCode == 404 ? notFound : null,
        ),
        throwsA(same(notFound)),
      );
    });

    test("mapError returning null keeps the http error", () async {
      final proxy = _RecordingProxy(Response('{"error":"rate_limited"}', 429));

      await expectLater(
        api(proxy).send(
          const _GetThing({}),
          mapError: (e) => e.statusCode == 404 ? Exception("trade not found") : null,
        ),
        throwsA(isA<ProviderHttpException>().having((e) => e.statusCode, "statusCode", 429)),
      );
    });

    test("mapError is not consulted on a success", () async {
      var mapErrorCalled = false;
      final proxy = _RecordingProxy(Response("{}", 200));

      await api(proxy).send(
        const _GetThing({}),
        mapError: (e) {
          mapErrorCalled = true;
          return null;
        },
      );

      expect(mapErrorCalled, isFalse);
    });
  });
}
