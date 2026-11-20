import "package:bloc/bloc.dart";
import "package:cw_core/multisig/multisig_config.dart";

part "restore_multi_sig_event.dart";

part "restore_multi_sig_state.dart";

class RestoreMultiSigBloc extends Bloc<RestoreMultiSigEvent, RestoreMultiSigState> {
  RestoreMultiSigBloc() : super(RestoreMultiSigInitial()) {
    on<SetOptions>(_onSetOptions);
  }

  void _onSetOptions(SetOptions event, Emitter<RestoreMultiSigState> emit) {
    emit(RestoreMultiSigConnectSigners(event.walletName, event.threshold, event.signers, []));
  }

}
