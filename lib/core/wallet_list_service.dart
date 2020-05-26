import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/foundation.dart';

/*
*
* WalletCredentials
*
* */

abstract class WalletCredentials {
  const WalletCredentials({this.name, this.password});

  final String name;
  final String password;
}

/*
*
* WalletListService
*
* */

abstract class WalletListService<N extends WalletCredentials,
    RFS extends WalletCredentials, RFK extends WalletCredentials> {
  Future<void> create(N credentials);

  Future<void> restoreFromSeed(RFS credentials);

  Future<void> restoreFromKeys(RFK credentials);

  Future<void> openWallet(String name, String password);

  Future<bool> isWalletExit(String name);

  Future<void> remove(String wallet);
}

/*
*
* BitcoinRestoreWalletFromSeedCredentials
*
* */

class BitcoinNewWalletCredentials extends WalletCredentials {}

/*
*
* BitcoinRestoreWalletFromSeedCredentials
*
* */

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  const BitcoinRestoreWalletFromSeedCredentials(
      {String name, String password, this.mnemonic})
      : super(name: name, password: password);

  final String mnemonic;
}

/*
*
* BitcoinRestoreWalletFromWIFCredentials
*
* */

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  const BitcoinRestoreWalletFromWIFCredentials(
      {String name, String password, this.wif})
      : super(name: name, password: password);

  final String wif;
}

/*
*
* BitcoinWalletListService
*
* */

class BitcoinWalletListService extends WalletListService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials> {
  @override
  Future<void> create(BitcoinNewWalletCredentials credentials) async {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<bool> isWalletExit(String name) async {
    // TODO: implement isWalletExit
    throw UnimplementedError();
  }

  @override
  Future<void> openWallet(String name, String password) async {
    // TODO: implement openWallet
    throw UnimplementedError();
  }

  Future<void> remove(String wallet) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromKeys(
      BitcoinRestoreWalletFromWIFCredentials credentials) async {
    // TODO: implement restoreFromKeys
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromSeed(
      BitcoinRestoreWalletFromSeedCredentials credentials) async {
    // TODO: implement restoreFromSeed
    throw UnimplementedError();
  }
}

/*
*
* BitcoinWalletListService
*
* */

class MoneroWalletListService extends WalletListService<
    BitcoinNewWalletCredentials,
    BitcoinRestoreWalletFromSeedCredentials,
    BitcoinRestoreWalletFromWIFCredentials> {
  @override
  Future<void> create(BitcoinNewWalletCredentials credentials) async {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<bool> isWalletExit(String name) async {
    // TODO: implement isWalletExit
    throw UnimplementedError();
  }

  @override
  Future<void> openWallet(String name, String password) async {
    // TODO: implement openWallet
    throw UnimplementedError();
  }

  Future<void> remove(String wallet) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromKeys(
      BitcoinRestoreWalletFromWIFCredentials credentials) async {
    // TODO: implement restoreFromKeys
    throw UnimplementedError();
  }

  @override
  Future<void> restoreFromSeed(
      BitcoinRestoreWalletFromSeedCredentials credentials) async {
    // TODO: implement restoreFromSeed
    throw UnimplementedError();
  }
}

/*
*
* SignUpState
*
* */

abstract class WalletCreationState {}

class WalletCreating extends WalletCreationState {}

class WalletCreatedSuccessfully extends WalletCreationState {}

class WalletCreationFailure extends WalletCreationState {
  WalletCreationFailure({@required this.error});

  final String error;
}

/*
*
* WalletCreationService
*
* */

class WalletCreationService {
  WalletCreationState state;
  WalletListService _service;

  void changeWalletType({@required WalletType type}) {
    switch (type) {
      case WalletType.monero:
        _service = MoneroWalletListService();
        break;
      case WalletType.bitcoin:
        _service = BitcoinWalletListService();
        break;
      default:
        break;
    }
  }

  Future<void> create(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.create(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  Future<void> restoreFromKeys(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.create(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }

  Future<void> restoreFromSeed(WalletCredentials credentials) async {
    try {
      state = WalletCreating();
      await _service.create(credentials);
      state = WalletCreatedSuccessfully();
    } catch (e) {
      state = WalletCreationFailure(error: e.toString());
    }
  }
}

/*
*
* AuthService
*
* */

//abstract class LoginState {}

abstract class SetupPinCodeState {}

class InitialSetupPinCodeState extends SetupPinCodeState {}

class SetupPinCodeInProgress extends SetupPinCodeState {}

class SetupPinCodeFinishedSuccessfully extends SetupPinCodeState {}

class SetupPinCodeFinishedFailure extends SetupPinCodeState {
  SetupPinCodeFinishedFailure({@required this.error});

  final String error;
}

class AuthService {
  SetupPinCodeState setupPinCodeState;

  Future<void> setupPinCode({@required String pin}) async {}

  Future<bool> authenticate({@required String pin}) async {
    return false;
  }

  void resetSetupPinCodeState() =>
      setupPinCodeState = InitialSetupPinCodeState();
}

/*
*
* SignUpService
*
* */

class SignUpService {
  SignUpService(
      {@required this.walletCreationService, @required this.authService});

  WalletCreationService walletCreationService;
  AuthService authService;
}

/*
*
* AppService
*
* */

class AppService {}
