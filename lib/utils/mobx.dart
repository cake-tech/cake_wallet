import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/keyable.dart';


typedef Filter<T> = bool Function(T);
typedef Transform<T, Y> = Y Function(T);




extension MobxBindable<T extends Keyable> on Box<T> {

  StreamSubscription<BoxEvent> bindToListWithTransform<Y extends Keyable>(
    ObservableList<Y> dest,
    Transform<T, Y> transform, {
    bool initialFire = false,
    Filter<T>? filter,
  }) {
    if (initialFire) {
      dest.addAll(values.map((value) => transform(value)));
    }

    return watch().listen((event) {
      if (filter != null && event.value != null && !filter(event.value as T)) {
        return;
      }

      dest.acceptBoxChange(event, transformed: event.deleted ? null : transform(event.value as T));
    });
  }
}

extension HiveBindable<T extends Keyable> on ObservableList<T> {


  void acceptBoxChange(BoxEvent event, {T? transformed}) {
    if (event.deleted) {
      removeWhere((el) {
        return el.keyIndex == event.key;
      });

      return;
    }

    final dynamic value = transformed ?? event.value;

    if (value is T) {
      final index = indexWhere((el) => el.keyIndex == value.keyIndex);

      if (index > -1) {
        this.setAll(index, [value]); // FIXME: fixme
      } else {
        add(value);
      }
    }
  }

}
