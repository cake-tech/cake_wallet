import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';
import 'package:path/path.dart' as p;

part 'print_verbose_view_model.g.dart';
class PrintVerboseViewModel = PrintVerboseViewModelBase with _$PrintVerboseViewModel;

abstract class PrintVerboseViewModelBase with Store {
  PrintVerboseViewModelBase();

  @observable
  String? logFilePath;

  final logDirecoryPath = p.dirname(printVLogFilePath!);
}