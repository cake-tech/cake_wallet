import 'package:cw_bitcoin/payjoin/payjoin_event_store.dart';
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinSenderPersister extends pj.JsonSenderSessionPersister {
  final PayjoinEventStore _store;
  final String _key;

  PayjoinSenderPersister(this._store, String sessionId)
      : _key = PayjoinEventStore.senderKey(sessionId);

  @override
  void save(String event) => _store.append(_key, event);

  @override
  List<String> load() => _store.load(_key);

  @override
  void close() {}
}

class PayjoinReceiverPersister extends pj.JsonReceiverSessionPersister {
  final PayjoinEventStore _store;
  final String _key;

  PayjoinReceiverPersister(this._store, String sessionId)
      : _key = PayjoinEventStore.receiverKey(sessionId);

  @override
  void save(String event) => _store.append(_key, event);

  @override
  List<String> load() => _store.load(_key);

  @override
  void close() {}
}
