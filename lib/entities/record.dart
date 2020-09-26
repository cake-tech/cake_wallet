import 'dart:async';

import 'package:cake_wallet/utils/mobx.dart';
import 'package:hive/hive.dart';

abstract class Record<T extends HiveObject> with Keyable {
  Record(this._source, this.original) {
    _listener?.cancel();
    _listener = _source.watch(key: original.key).listen((event) {
      if (!event.deleted) {
        fromBind(event.value as T);
      }
    });

    fromBind(original);
    toBind(original);
  }

  dynamic get key => original.key;

  @override
  dynamic get keyIndex => key;

  final T original;

  final Box<T> _source;

  StreamSubscription<BoxEvent> _listener;

  void fromBind(T original);

  void toBind(T original);

  Future<void> save() => original.save();
}
