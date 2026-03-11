import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/lnurlpay_record.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:meta/meta.dart';

part 'lightning_username_event.dart';

part 'lightning_username_state.dart';

class UsernameError {
  String message;
  bool isInfo;

  UsernameError(this.message, {this.isInfo = false});
}

// TODO find other errors that api returns
final Map<String, String> errorPatterns = {"name already taken": S.current.username_not_available};

const usernameRegex = r"^[a-z0-9_.-]+$";
const usernameSuffix = "@cake.cash";

class LightningUsernameBloc extends Bloc<LightningUsernameEvent, LightningUsernameState> {
  final WalletBase _wallet;

  LightningUsernameBloc(this._wallet) : super(LightningUsernameInitial("")) {
    on<ChangeUsername>(onUsernameChanged, transformer: restartable());

    on<RequestUsernameSave>(onUsernameSaveRequested);

    on<_Init>((event, emit) async {
      final username = await bitcoin!.getLightningUsername(_wallet);
      emit(LightningUsernameInitial(username ?? ""));
    });

    add(_Init());
  }

  Future<void> onUsernameChanged(ChangeUsername event, Emitter<LightningUsernameState> emit) async {
    emit(LightningUsernameChecking(event.newUsername));

    final error = await getUsernameError(event.newUsername);

    if (error != null) {
      emit(LightningUsernameError(event.newUsername, error));
    } else {
      emit(LightningUsernameReady(event.newUsername));
    }
  }

  Future<void> onUsernameSaveRequested(RequestUsernameSave event, Emitter<LightningUsernameState> emit) async {
    emit(LightningUsernameSaving(state.username));
    try {
      await bitcoin!.setLightningUsername(_wallet, state.username);
      emit(LightningUsernameSaved(state.username));
    } catch (e) {
      for (final pattern in errorPatterns.keys) {
        if (e.toString().contains(pattern)) {
          emit(LightningUsernameError(state.username, UsernameError(errorPatterns[pattern]!)));
          return;
        }
      }
      emit(LightningUsernameError(state.username, UsernameError(bitcoin!.getBreezSdkError(e) ?? e.toString())));
    }
  }

  Future<UsernameError?> getUsernameError(String username) async {
    if (!(RegExp(usernameRegex).hasMatch(username))) {
      return UsernameError("${S.current.username_character_error} a-z, 0-9, -  _  .");
    }

    if (username.length < 1 || username.length > 64) {
      return UsernameError(S.current.username_length_error_1_64);
    }

    if (username == (await bitcoin!.getLightningUsername(_wallet))) {
      return UsernameError(S.current.already_your_username, isInfo: true);
    }

    if ((await LNUrlPayRecord.checkWellKnownUsername(
            "${username}${usernameSuffix}", CryptoCurrency.btc)) !=
        null) {
      return UsernameError(S.current.username_not_available);
    }

    return null;
  }
}
