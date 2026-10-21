import "package:cw_core/utils/proxy_wrapper.dart";
import "package:http/http.dart";

/// One http call a provider made, so a test can assert what actually went out.
class MockRequest {
  const MockRequest({required this.method, required this.uri, this.body});

  final String method;
  final Uri uri;
  final String? body;

  String get path => uri.path;

  Map<String, String> get query => uri.queryParameters;

  /// Everything the provider put on the wire, url and payload together. Handy for
  /// "did it tell the exchange where to send the coins" style assertions, which is the
  /// same question whether the provider uses query params or a json body.
  String get wire => "$uri ${body ?? ""}";

  @override
  String toString() => "$method $uri${body == null ? "" : " $body"}";
}

/// A canned answer for one route.
class MockResponse {
  const MockResponse(this.body, {this.statusCode = 200});

  const MockResponse.created(this.body) : statusCode = 201;

  const MockResponse.notFound(this.body) : statusCode = 404;

  const MockResponse.badRequest(this.body) : statusCode = 400;

  final String body;
  final int statusCode;
}

/// Base for the per-provider proxy wrappers under `mocks/`.
///
/// [ProxyWrapper]'s only generative constructor is private and it is a singleton, so this
/// implements the interface instead of extending it. The providers only ever reach for
/// get/post/put/delete; [noSuchMethod] makes everything else (socket and http client
/// plumbing) fail loudly rather than silently doing something.
abstract class MockProxyWrapper implements ProxyWrapper {
  /// Every call the provider made, in order.
  final List<MockRequest> requests = [];

  /// The canned answer for [request].
  ///
  /// Return null when the mock has no route for it — that throws instead of answering a
  /// 404, because an unrouted call means the provider went somewhere this mock does not
  /// know about, which a test should hear about rather than quietly pass or fail on a
  /// misleading error.
  MockResponse? route(MockRequest request);

  /// Concatenation of every url and body sent so far.
  String get wire => requests.map((request) => request.wire).join("\n");

  List<MockRequest> requestsTo(String path) =>
      requests.where((request) => request.path == path).toList();

  @override
  Future<Response> get({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) => _answer("GET", clearnetUri ?? onionUri, null);

  @override
  Future<Response> post({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
    bool allowMitmMoneroBypassSSLCheck = false,
  }) => _answer("POST", clearnetUri ?? onionUri, body);

  @override
  Future<Response> put({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
    String? body,
  }) => _answer("PUT", clearnetUri ?? onionUri, body);

  @override
  Future<Response> delete({
    Map<String, String>? headers,
    int? portOverride,
    Uri? clearnetUri,
    Uri? onionUri,
  }) => _answer("DELETE", clearnetUri ?? onionUri, null);

  Future<Response> _answer(String method, Uri? uri, String? body) async {
    if (uri == null) {
      throw ArgumentError("$runtimeType was called without a uri");
    }

    final request = MockRequest(method: method, uri: uri, body: body);
    requests.add(request);

    final response = route(request);

    if (response == null) {
      throw StateError("$runtimeType has no canned response for $request");
    }

    return Response(response.body, response.statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    "${invocation.memberName} is not mocked - the exchange providers should only be "
    "reaching the network through get/post/put/delete",
  );
}
