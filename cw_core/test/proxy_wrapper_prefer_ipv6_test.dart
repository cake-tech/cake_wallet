import "dart:io";

import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:flutter_test/flutter_test.dart";

/// Answers every request with the client address the server saw.
Future<HttpServer> _clientAddressEchoServer(InternetAddress address) async {
  final server = await HttpServer.bind(address, 0);
  server.listen((request) async {
    await request.drain<void>();
    request.response.write(request.connectionInfo!.remoteAddress.address);
    await request.response.close();
  });
  return server;
}

void main() {
  setUpAll(() => CakeTor.instance = CakeTorDisabled());

  test("preferIPv6 falls back to the normal request when IPv6 cannot connect", () async {
    // IPv4 loopback only: the IPv6 attempt to [::1] is refused, or never starts without IPv6.
    final server = await _clientAddressEchoServer(InternetAddress.loopbackIPv4);
    addTearDown(() => server.close(force: true));

    final response = await ProxyWrapper().post(
      clearnetUri: Uri.parse("http://localhost:${server.port}/"),
      body: "{}",
      preferIPv6: true,
    );

    expect(response.statusCode, 200);
    expect(response.body, "127.0.0.1");
  });

  test("preferIPv6 connects over IPv6 when it works", () async {
    final HttpServer server;
    try {
      // Dual-stack: accepts both families and reports which one the client used.
      server = await _clientAddressEchoServer(InternetAddress.anyIPv6);
    } on SocketException {
      return; // No IPv6 on this machine (some CI containers).
    }
    addTearDown(() => server.close(force: true));
    final localhost = await InternetAddress.lookup("localhost", type: InternetAddressType.IPv6)
        .catchError((Object _) => <InternetAddress>[]);
    if (!localhost.any((address) => address.address == "::1")) {
      return;
    }

    final response = await ProxyWrapper().post(
      clearnetUri: Uri.parse("http://localhost:${server.port}/"),
      body: "{}",
      preferIPv6: true,
    );

    expect(response.statusCode, 200);
    expect(response.body, "::1");
  });
}
