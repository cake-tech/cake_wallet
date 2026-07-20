import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'rate_state.dart';

class RateCubit extends Cubit<RateState> {
  RateCubit() : super(RateInitial());
}
