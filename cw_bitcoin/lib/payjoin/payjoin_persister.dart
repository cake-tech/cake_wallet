import "package:cw_bitcoin/payjoin/payjoin_event_store.dart";
import "package:payjoin/payjoin.dart" as pj;

class PayjoinSenderPersister extends pj.JsonSenderSessionPersister {
  PayjoinSenderPersister(this._store, String sessionId)
      : _key = PayjoinEventStore.senderKey(sessionId);

  final PayjoinEventStore _store;
  final String _key;

  @override
  void save(String event) => _store.append(_key, event);

  @override
  List<String> load() => _store.load(_key);

  @override
  void close() {}
}

class PayjoinReceiverPersister extends pj.JsonReceiverSessionPersister {
  PayjoinReceiverPersister(this._store, String sessionId)
      : _key = PayjoinEventStore.receiverKey(sessionId);

  final PayjoinEventStore _store;
  final String _key;

  @override
  void save(String event) => _store.append(_key, event);

  @override
  List<String> load() => _store.load(_key);

  @override
  void close() {}
}
