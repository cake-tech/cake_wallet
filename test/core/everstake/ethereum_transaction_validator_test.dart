import "package:cake_wallet/core/everstake/ethereum_transaction_validator.dart";
import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

// Responses from wallet-sdk-api.everstake.com for real mainnet stakers.
const _stake = <String, dynamic>{
  "from": "0x15273714bdfed50e922c4cdd35ed50291780b392",
  "to": "0xD523794C879D9eC028960a231F866758e405bE34",
  "value": 0.12345678901234568,
  "gasLimit": 479948,
  "data": "0x3a29dbae0000000000000000000000000000000000000000000000000000000000000000",
};

const _unstake = <String, dynamic>{
  "from": "0x15273714bdfed50e922c4cdd35ed50291780b392",
  "value": 0,
  "to": "0xD523794C879D9eC028960a231F866758e405bE34",
  "gasLimit": 406244,
  "data":
      "0x76ec871c00000000000000000000000000000000000000000000000006f05b59d3b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
};

const _unstakePending = <String, dynamic>{
  "from": "0xd5ecda14db847eeab757cc65c7c6a961583160aa",
  "value": 0,
  "to": "0xD523794C879D9eC028960a231F866758e405bE34",
  "gasLimit": 355492,
  "data": "0xed0723d400000000000000000000000000000000000000000000000000b1a2bc2ec50000",
};

const _claim = <String, dynamic>{
  "from": "0xc47345fe0311ce2e208a9c5b4a1ff536cb52012b",
  "to": "0x7a7f0b3c23C23a31cFcb0c44709be70d4D545c6e",
  "value": 0,
  "gasLimit": 398400,
  "data": "0x33986ffa",
};

void main() {
  const staker = "0x15273714bdfed50e922c4cdd35ed50291780b392";
  const pendingStaker = "0xd5ecda14db847eeab757cc65c7c6a961583160aa";
  const claimer = "0xc47345fe0311ce2e208a9c5b4a1ff536cb52012b";
  final validator = EverstakeEthereumTransactionValidator();

  Money eth(String amount) => Money.parse(amount, CryptoCurrency.eth);

  // Mirrors EverstakeService: a stake carries the requested amount, every other call carries none.
  EverstakeEthereumTransaction transaction(Map<String, dynamic> json, {Money? value}) =>
      EverstakeEthereumTransaction.fromJson(json, value: value ?? Money.zero(CryptoCurrency.eth));

  Matcher rejectsFor(String reason) => throwsA(
        isA<EverstakeException>().having((e) => e.message, "message", contains(reason)),
      );

  group("accepts the transactions Everstake builds", () {
    test("stake", () {
      final amount = eth("0.123456789012345678");

      expect(
        () => validator.validateStake(
          transaction(_stake, value: amount),
          address: staker,
          amount: amount,
          source: "0",
        ),
        returnsNormally,
      );
    });

    test("unstake", () {
      expect(
        () => validator.validateUnstake(
          transaction(_unstake),
          address: staker,
          amount: eth("0.5"),
          allowedInterchangeNum: 0,
          source: "0",
        ),
        returnsNormally,
      );
    });

    test("unstake pending", () {
      expect(
        () => validator.validateUnstakePending(
          transaction(_unstakePending),
          address: pendingStaker,
          amount: eth("0.05"),
        ),
        returnsNormally,
      );
    });

    test("claim withdrawal", () {
      expect(
        () => validator.validateClaimWithdrawRequest(transaction(_claim), address: claimer),
        returnsNormally,
      );
    });
  });

  group("rejects a transaction that doesn't match the request", () {
    test("a stake sent to another address", () {
      final amount = eth("0.123456789012345678");

      expect(
        () => validator.validateStake(
          transaction(
            {..._stake, "to": "0x000000000000000000000000000000000000dEaD"},
            value: amount,
          ),
          address: staker,
          amount: amount,
          source: "0",
        ),
        rejectsFor("contract"),
      );
    });

    test("a stake carrying the API's rounded value", () {
      expect(
        () => validator.validateStake(
          transaction(_stake, value: eth("0.12345678901234568")),
          address: staker,
          amount: eth("0.123456789012345678"),
          source: "0",
        ),
        rejectsFor("value"),
      );
    });

    test("a stake carrying a different source", () {
      final amount = eth("0.123456789012345678");

      expect(
        () => validator.validateStake(
          transaction(_stake, value: amount),
          address: staker,
          amount: amount,
          source: "1",
        ),
        rejectsFor("data"),
      );
    });

    test("an unstake for a different amount", () {
      expect(
        () => validator.validateUnstake(
          transaction(_unstake),
          address: staker,
          amount: eth("0.4"),
          allowedInterchangeNum: 0,
          source: "0",
        ),
        rejectsFor("data"),
      );
    });

    test("an unstake returned for a claim", () {
      expect(
        () => validator.validateClaimWithdrawRequest(transaction(_unstake), address: staker),
        rejectsFor("contract"),
      );
    });

    test("a transaction built for another address", () {
      expect(
        () => validator.validateUnstakePending(
          transaction(_unstakePending),
          address: staker,
          amount: eth("0.05"),
        ),
        rejectsFor("sender"),
      );
    });
  });
}
