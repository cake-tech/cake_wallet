import 'package:mobx/mobx.dart';

Dispose connectDifferent<T, Y>(ObservableList<T> source, ObservableList<Y> dest,
    Y Function(T) transform, {bool Function(T) filter}) {
  return source.observe((change) {
    switch (change.type) {
      case OperationType.add:
        final _values = change.added;
        Iterable<T> values;

        if (filter != null) {
          values = _values.where(filter);
        }

        dest.addAll(values.map((e) => transform(e)));
        break;
      case OperationType.remove:
        print(change.index);
        print(change.removed);
        change.removed.forEach((element) { dest.remove(element); });

//        dest.removeAt(change.index);
        break;
      case OperationType.update:
//        change.index
        break;
    }
  });
}

Dispose connect<T>(ObservableList<T> source, ObservableList<T> dest) {
  return source.observe((change) {
    switch (change.type) {
      case OperationType.add:
        dest.addAll(change.added);
        break;
      case OperationType.remove:
        dest.removeAt(change.index);
        break;
      case OperationType.update:
//        change.index
        break;
    }
  });
}
