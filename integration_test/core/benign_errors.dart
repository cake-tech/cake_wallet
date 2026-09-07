String? benignErrorKind(String message) {
  if (_toleratedAssertions.any(message.contains)) {
    return "assertion";
  }

  if (_toleratedAssets.any(message.contains)) {
    return "asset";
  }

  if (_toleratedNetworkNoise.any(message.contains)) {
    return "network";
  }

  return null;
}

// Debug build assertions. The semantics ones are real accessibility bugs that already
// exist on dev, take them off this list once they are fixed.
const List<String> _toleratedAssertions = [
  "overflowed by",
  "minValue, and maxValue must be valid numbers",
  "node.parent?._dirty",
  "RenderBox was not laid out",
];

// CakeImageWidget reports these before falling back to the svg
const List<String> _toleratedAssets = [
  "Unable to load asset",
  "NetworkImageLoadException",
  "Failed to load network image",
];

// The same failures exception_handler.dart ignores
const List<String> _toleratedNetworkNoise = [
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
