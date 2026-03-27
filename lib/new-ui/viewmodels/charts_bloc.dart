import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'charts_event.dart';
part 'charts_state.dart';

class ChartsBloc extends Bloc<ChartsEvent, ChartsState> {
  ChartsBloc() : super(ChartsInitial()) {
    on<ChartsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
