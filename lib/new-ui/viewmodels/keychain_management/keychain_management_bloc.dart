import "package:bloc/bloc.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:encrypt/encrypt.dart";
import "package:meta/meta.dart";

part "keychain_management_event.dart";
part "keychain_management_state.dart";

class KeychainManagementBloc extends Bloc<KeychainManagementEvent, KeychainManagementState> {
  KeychainManagementBloc({required CwKeychain keychain}) : _keychain = keychain, super(KeychainManagementNotLoaded()) {
    on<KeychainManagementEvent>((event, emit) {
      // TODO: implement event handler
    });
  }

  final CwKeychain _keychain;
}
