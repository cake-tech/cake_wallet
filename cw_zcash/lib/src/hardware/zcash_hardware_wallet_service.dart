import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:zkool/src/rust/api/coin.dart" as zkool_coin;

abstract class ZcashHardwareWalletService extends HardwareWalletService {
  ZcashHardwareWalletService(this.coin);

  final zkool_coin.Coin? coin;

  ZcashHardwareWalletService withCoin(zkool_coin.Coin coin) => throw UnimplementedError();
}
