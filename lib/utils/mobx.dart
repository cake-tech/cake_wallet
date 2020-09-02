import 'package:mobx/mobx.dart';

void connectDifferent<T, Y>(
    ObservableList<T> source, ObservableList<Y> dest, Y Function(T) transform,
    {bool Function(T) filter}) {
  source.observe((ListChange<T> change) {
//     switch (change.type) {
//       case OperationType.add:
//         final _values = change.added;
//         Iterable<T> values;

//         if (filter != null) {
//           values = _values.where(filter);
//         }

//         dest.addAll(values.map((e) => transform(e)));
//         break;
//       case OperationType.remove:
//         change.removed.forEach((element) {
//           dest.remove(element);
//         });

// //        dest.removeAt(change.index);
//         break;
//       case OperationType.update:
// //        change.index
//         break;
//     }
  });
}

void connect<T>(ObservableList<T> source, ObservableList<T> dest) {
  source.observe((ListChange<T> change) {
//     switch (change.type) {
//       case OperationType.add:
//         dest.addAll(change.added);
//         break;
//       case OperationType.remove:
//         dest.removeAt(change.index);
//         break;
//       case OperationType.update:
// //        change.index
//         break;
//     }
  });
}
