import "package:cake_wallet/core/everstake/ethereum_pool.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

const _pool = "0xd523794c879d9ec028960a231f866758e405be34";
const _accounting = "0x7a7f0b3c23c23a31cfcb0c44709be70d4d545c6e";

Money _eth(String amount) => Money.parse(amount, CryptoCurrency.eth);

void main() {
  final pool = EverstakeEthereumPool((_) => throw UnimplementedError());

  // The expected data is what wallet-sdk-api.everstake.com built for real mainnet stakers.
  group("encodes the calls Everstake's API builds", () {
    test("a stake, carrying the exact amount", () {
      expect(
        pool.stakeCall(_eth("0.123456789012345678")),
        (
          to: _pool,
          data: "0x3a29dbae0000000000000000000000000000000000000000000000000000000000000000",
          value: _eth("0.123456789012345678"),
        ),
      );
    });

    test("an unstake", () {
      expect(
        pool.unstakeCall(_eth("0.5")),
        (
          to: _pool,
          data:
              "0x76ec871c00000000000000000000000000000000000000000000000006f05b59d3b2000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000",
          value: _eth("0"),
        ),
      );
    });

    test("a pending unstake", () {
      expect(
        pool.unstakePendingCall(_eth("0.05")),
        (
          to: _pool,
          data: "0xed0723d400000000000000000000000000000000000000000000000000b1a2bc2ec50000",
          value: _eth("0"),
        ),
      );
    });

    test("a withdrawal claim", () {
      expect(
        pool.claimWithdrawRequestCall(),
        (to: _accounting, data: "0x33986ffa", value: _eth("0")),
      );
    });
  });
}
