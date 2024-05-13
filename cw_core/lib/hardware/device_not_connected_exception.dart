class DeviceNotConnectedException implements Exception {
  final String message;

  DeviceNotConnectedException({
    this.message = '',
  });
}
