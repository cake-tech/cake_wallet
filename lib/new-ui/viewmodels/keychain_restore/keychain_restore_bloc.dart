import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'keychain_restore_event.dart';
part 'keychain_restore_state.dart';

class KeychainRestoreBloc extends Bloc<KeychainRestoreEvent, KeychainRestoreState> {
  KeychainRestoreBloc() : super(KeychainRestoreInitial()) {
    on<KeychainRestoreEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
