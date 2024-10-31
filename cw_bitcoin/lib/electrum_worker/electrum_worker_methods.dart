class ElectrumWorkerMethods {
  const ElectrumWorkerMethods._(this.method);
  final String method;

  static const String connectionMethod = "connection";
  static const String unknownMethod = "unknown";

  static const ElectrumWorkerMethods connect = ElectrumWorkerMethods._(connectionMethod);
  static const ElectrumWorkerMethods unknown = ElectrumWorkerMethods._(unknownMethod);

  @override
  String toString() {
    return method;
  }
}
