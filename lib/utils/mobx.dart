import 'dart:async';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

mixin Keyable {
  dynamic keyIndex;
}

void connectWithTransform<T extends Keyable, Y extends Keyable>(
    ObservableList<T> source, ObservableList<Y> dest, Y Function(T) transform,
    {bool Function(T) filter}) {
  source.observe((ListChange<T> change) {
    change.elementChanges.forEach((change) {
      switch (change.type) {
        case OperationType.add:
          if (filter?.call(change.newValue as T) ?? true) {
            dest.add(transform(change.newValue as T));
          }
          break;
        case OperationType.remove:
          // Hive could has equal index and key
          dest.removeWhere(
              (elem) => elem.keyIndex == (change.oldValue.key ?? change.index));
          break;
        case OperationType.update:
          for (var i = 0; i < dest.length; i++) {
            final item = dest[i];

            if (item.keyIndex == change.newValue.key) {
              dest[i] = transform(change.newValue as T);
            }
          }
          break;
      }
    });
  });
}

void connectMapToListWithTransform<T extends Keyable, Y extends Keyable>(
    ObservableMap<dynamic, T> source,
    ObservableList<Y> dest,
    Y Function(T) transform,
    {bool Function(T) filter}) {
  source.observe((MapChange<dynamic, T> change) {
    switch (change.type) {
      case OperationType.add:
        if (filter?.call(change.newValue) ?? true) {
          dest.add(transform(change.newValue));
        }
        break;
      case OperationType.remove:
        // Hive could has equal index and key
        dest.removeWhere(
            (elem) => elem.keyIndex == (change.key ?? change.newValue.keyIndex));
        break;
      case OperationType.update:
        for (var i = 0; i < dest.length; i++) {
          final item = dest[i];

          if (item.keyIndex == change.key) {
            dest[i] = transform(change.newValue);
          }
        }
        break;
    }
  });
}

void connect<T extends Keyable>(
    ObservableList<T> source, ObservableList<T> dest) {
  source.observe((ListChange<T> change) {
    source.observe((ListChange<T> change) {
      change.elementChanges.forEach((change) {
        switch (change.type) {
          case OperationType.add:
            // if (filter?.call(change.newValue as T) ?? true) {
            dest.add(change.newValue as T);
            // }
            break;
          case OperationType.remove:
            // Hive could has equal index and key
            dest.removeWhere((elem) =>
                elem.keyIndex == (change.oldValue.key ?? change.index));
            break;
          case OperationType.update:
            for (var i = 0; i < dest.length; i++) {
              final item = dest[i];

              if (item.keyIndex == change.newValue.key) {
                dest[i] = change.newValue as T;
              }
            }
            break;
        }
      });
    });
  });
}

StreamSubscription<BoxEvent> bindBox<T extends Keyable>(
    Box<T> source, ObservableList<T> dest) {
  return source.watch().listen((event) {
    if (event.deleted) {
      dest.removeWhere((el) => el.keyIndex == event.key);
    }

    final dynamic value = event.value;

    if (value is T) {
      final elIndex = dest.indexWhere((el) => el.keyIndex == value.keyIndex);

      if (elIndex > -1) {
        dest[elIndex] = value;
      } else {
        dest.add(value);
      }
    }
  });
}
