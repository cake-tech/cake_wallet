// Errors the app itself tolerates at runtime
bool isBenignError(String message) => _benignFragments.any(message.contains);

const List<String> _benignFragments = [
  // Debug build assertions. The semantics ones are real accessibility bugs that already
  // exist on dev, take them off this list once they are fixed.
  "overflowed by",
  "minValue, and maxValue must be valid numbers",
  "node.parent?._dirty",
  "RenderBox was not laid out",

  // CakeImageWidget reports these before falling back to the svg
  "Unable to load asset",
  "NetworkImageLoadException",
  "Failed to load network image",

  // The same failures exception_handler.dart ignores
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
