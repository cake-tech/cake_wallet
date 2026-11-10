import "package:cake_wallet/exchange/utils/deposit_wallet_utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  WalletInfo bitcoinWallet({HardwareWalletType? hardwareWalletType}) => WalletInfo.external(
        id: "id",
        name: "wallet",
        type: WalletType.bitcoin,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "",
        hardwareWalletType: hardwareWalletType,
      );

  group("depositWalletType", () {
    test("is null for a chain without wallets, so no source wallets are offered", () {
      expect(depositWalletType(CryptoCurrency.ada), isNull);
    });

    test("resolves coins, tokens and Lightning to the wallet type that holds them", () {
      expect(depositWalletType(CryptoCurrency.xmr), WalletType.monero);
      expect(depositWalletType(CryptoCurrency.usdttrc20), WalletType.tron);
      expect(depositWalletType(CryptoCurrency.btcln), WalletType.bitcoin);
    });
  });

  group("canFundDeposit", () {
    test("keeps hardware wallets out of Lightning deposits", () {
      expect(
        canFundDeposit(
          bitcoinWallet(hardwareWalletType: HardwareWalletType.ledger),
          CryptoCurrency.btcln,
        ),
        isFalse,
      );
      expect(canFundDeposit(bitcoinWallet(), CryptoCurrency.btcln), isTrue);
    });

    test("allows hardware wallets for on-chain deposits", () {
      expect(
        canFundDeposit(
          bitcoinWallet(hardwareWalletType: HardwareWalletType.ledger),
          CryptoCurrency.btc,
        ),
        isTrue,
      );
    });
  });
}
