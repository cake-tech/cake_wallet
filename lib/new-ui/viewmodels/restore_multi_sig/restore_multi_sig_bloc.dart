import "package:bloc/bloc.dart";
import "package:cw_core/multisig/multisig_config.dart";
import "package:cw_core/utils/print_verbose.dart";

part "restore_multi_sig_event.dart";

part "restore_multi_sig_state.dart";

class RestoreMultiSigBloc extends Bloc<RestoreMultiSigEvent, RestoreMultiSigState> {
  RestoreMultiSigBloc() : super(RestoreMultiSigInitial()) {
    on<SetOptions>(_onSetOptions);
    on<ConnectSigner>(_onConnectSigner);
  }

  void _onSetOptions(SetOptions event, Emitter<RestoreMultiSigState> emit) {
    emit(RestoreMultiSigConnectSigners(event.walletName, event.threshold, event.signers, []));
  }

  void _onConnectSigner(ConnectSigner event, Emitter<RestoreMultiSigState> emit) {

    printV(event.signer.toJson());
    if (state case final RestoreMultiSigConnectSigners s) {
      s.connectedSigners.add(event.signer);
      emit(s);
      printV(" dddddddd");
    }
  }

}
