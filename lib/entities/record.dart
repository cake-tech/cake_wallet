import 'dart:async';

import 'package:cake_wallet/utils/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/keyable.dart';

abstract class Record<T extends HiveObject> with Keyable {
  Record(this._source, this.original) {
    key = original.key;
    _listener?.cancel();
    _listener = _source.watch(key: original.key).listen((event) {
      if (!event.deleted) {
        fromBind(event.value as T);
      }
    });

    fromBind(original);
    toBind(original);
  }

  dynamic key;

  @override
  dynamic get keyIndex => key;

  final T original;

  final Box<T> _source;

  StreamSubscription<BoxEvent>? _listener;

  void fromBind(T original);

  void toBind(T original);

  Future<void> save() => original.save();
}
