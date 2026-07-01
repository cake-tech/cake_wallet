import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/keyable.dart';

void connectMapToListWithTransform<T extends Keyable, Y extends Keyable>(
    ObservableMap<dynamic, T> source,
    ObservableList<Y> dest,
    Y Function(T?) transform,
    {bool Function(T?)? filter}) {
  source.observe((MapChange<dynamic, T> change) {
    if (change.type == null) {
      return;
    }
    
    switch (change.type) {
      case OperationType.add:
        if (filter?.call(change.newValue) ?? true) {
          dest.add(transform(change.newValue));
        }
        break;
      case OperationType.remove:
        // Hive could has equal index and key
        dest.removeWhere((elem) =>
            elem.keyIndex == (change.key ?? change.newValue?.keyIndex));
        break;
      case OperationType.update:
        for (var i = 0; i < dest.length; i++) {
          final item = dest[i];

          if (item.keyIndex == change.key) {
            dest[i] = transform(change.newValue);
          }
        }
        break;
      default:
        break;
    }
  });
}

typedef Filter<T> = bool Function(T);
typedef Transform<T, Y> = Y Function(T);

enum ChangeType { update, delete, add }

class EntityChange<T extends Keyable> {
  EntityChange(this.value, this.type, {dynamic key}) : _key = key;

  dynamic get key => _key ?? value.keyIndex;
  final T value;
  final ChangeType type;
  final dynamic _key;
}

extension MobxBindable<T extends Keyable> on Box<T> {
  StreamSubscription<BoxEvent> bindToList(
    ObservableList<T> dest, {
    bool initialFire = false,
    Filter<T>? filter,
  }) {
    if (initialFire) {
      final res = filter != null ? values.where(filter) : values;
      dest.addAll(res);
    }

    return watch().listen((event) {
      if (filter != null && event.value != null && !filter(event.value as T)) {
        return;
      }

      dest.acceptBoxChange(event);
    });
  }

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

      dest.acceptBoxChange(event,
          transformed: event.deleted ? null : transform(event.value as T));
    });
  }
}

extension HiveBindable<T extends Keyable> on ObservableList<T> {
  Stream<EntityChange<T>> listen() {
    // ignore: close_sinks
    final controller = StreamController<EntityChange<T>>();

    observe((ListChange<T> change) {
      change.elementChanges?.forEach((change) {
        ChangeType type;

        switch (change.type) {
          case OperationType.add:
            type = ChangeType.add;
            break;
          case OperationType.remove:
            type = ChangeType.delete;
            break;
          case OperationType.update:
            type = ChangeType.update;
            break;
        }

        final value = change.newValue as T;
        controller.add(EntityChange(value, type,
            key: type == ChangeType.delete ? change.index : value.keyIndex));
      });
    });

    return controller.stream;
  }

  StreamSubscription<EntityChange<T>> bindToList(ObservableList<T> dest) =>
      listen().listen((event) => dest.acceptEntityChange(event));

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

  void acceptEntityChange(EntityChange<T> event) {
    if (event.type == ChangeType.delete) {
      removeWhere((el) => el.keyIndex == event.key);
      return;
    }

    final dynamic value = event.value;

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
