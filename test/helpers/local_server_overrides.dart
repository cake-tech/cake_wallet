import "dart:io";

class LocalServerOverrides extends HttpOverrides {
  LocalServerOverrides(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)
    ..connectionFactory =
        (uri, proxyHost, proxyPort) => Socket.startConnect(InternetAddress.loopbackIPv4, port);
}
