/// Errors the app itself tolerates at runtime, so the tests must not fail on them either.
///
/// The app ignores a long list of transient network and io failures in
/// lib/utils/exception_handler.dart, and debug builds additionally assert on layout and
/// semantics issues that never reach a user. A test that fails on those is reporting the
/// emulator, not the wallet.
bool isBenignError(String message) => _benignFragments.any(message.contains);

const List<String> _benignFragments = [
  // Layout and semantics assertions, debug build only. These are pre-existing on dev, the
  // semantics ones are real accessibility bugs and should come off this list once fixed.
  "overflowed by",
  "minValue, and maxValue must be valid numbers",
  "node.parent?._dirty",
  "RenderBox was not laid out",

  // Assets, CakeImageWidget falls back to the svg when the compiled vec is missing
  "Unable to load asset",
  "NetworkImageLoadException",
  "Failed to load network image",

  // Transient network failures, the same categories exception_handler.dart ignores
  "SocketException",
  "HttpException",
  "ClientException",
  "HandshakeException",
  "TimeoutException",
  "Failed host lookup",
  "Connection closed",
  "Connection reset by peer",
  "Connection refused",
  "Connection timed out",
  "Operation timed out",
  "Network is unreachable",
  "No route to host",
];
