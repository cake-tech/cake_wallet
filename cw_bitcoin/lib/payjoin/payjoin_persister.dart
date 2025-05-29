import 'package:payjoin_flutter/src/generated/api/receive.dart';
import 'package:payjoin_flutter/src/generated/api/send.dart';

class PayjoinSenderPersister implements DartSenderPersister {
  static DartSenderPersister impl() {
    final impl = PayjoinSenderPersister();
    return DartSenderPersister(
      save: (sender) => impl.save(sender: sender),
      load: (token) => impl.load(token: token),
    );
  }

  final Map<String, FfiSender> _store = {};

  Future<SenderToken> save({required FfiSender sender}) async {
    final token = sender.key();
    _store[token.toBytes().toString()] = sender;
    return token;
  }

  Future<FfiSender> load({required SenderToken token}) async {
    final sender = _store[token.toBytes().toString()];
    if (sender == null) {
      throw Exception('Sender not found for the provided token.');
    }
    return sender;
  }

  @override
  void dispose() => _store.clear();

  @override
  bool get isDisposed => _store.isEmpty;
}

class PayjoinReceiverPersister implements DartReceiverPersister {
  static DartReceiverPersister impl() {
    final impl = PayjoinReceiverPersister();
    return DartReceiverPersister(
      save: (receiver) => impl.save(receiver: receiver),
      load: (token) => impl.load(token: token),
    );
  }

  final Map<String, FfiReceiver> _store = {};

  Future<ReceiverToken> save({required FfiReceiver receiver}) async {
    final token = receiver.key();
    _store[token.toBytes().toString()] = receiver;
    return token;
  }

  Future<FfiReceiver> load({required ReceiverToken token}) async {
    final receiver = _store[token.toBytes().toString()];
    if (receiver == null) {
      throw Exception('Receiver not found for the provided token.');
    }
    return receiver;
  }

  @override
  void dispose() => _store.clear();

  @override
  bool get isDisposed => _store.isEmpty;
}
