import 'package:cake_wallet/entities/node.dart';

class NodeSSL {
  NodeSSL(this._node) :
  _useSSL = _node.useSSL ?? false;

  final Node _node;
  final bool _useSSL;

  bool get useSSL => _useSSL;
}