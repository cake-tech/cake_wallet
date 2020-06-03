import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';

part 'app_service.g.dart';

class AppService = AppServiceBase with _$AppService;

abstract class AppServiceBase with Store {
  AppServiceBase({this.walletCreationService, this.authService, this.wallet});

  WalletCreationService walletCreationService;
  AuthService authService;
  WalletBase wallet;
}