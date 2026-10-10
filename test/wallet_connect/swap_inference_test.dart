import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/swap_inference.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:on_chain/solana/solana.dart";

import "abi_hex.dart";
import "stubs.dart";

const signer = "4WweZC1DjbanK9JukCn4JixAGPqSG1KnzW1wqz3x9e2t";
const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const usdtMint = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";
const wsolMint = SolanaProgramIds.wrappedSolMint;
const jupiter = SolanaProgramIds.jupiterV6;
const systemProgram = SolanaProgramIds.systemProgram;
const tokenProgram = SolanaProgramIds.tokenProgram;
const ataProgram = SolanaProgramIds.associatedTokenProgram;

String ataFor(String owner, String mint) =>
    AssociatedTokenAccountProgramUtils.associatedTokenAccount(
      mint: SolAddress(mint),
      owner: SolAddress(owner),
    ).address.address;

/// TransferChecked: tag 12, u64 amount, u8 decimals.
List<int> transferChecked(BigInt amount, int decimals) => [12, ...u64Le(amount), decimals];

/// Anchor discriminator the engine knows, followed by in_amount and min_out.
List<int> jupiterRouteData(BigInt inAmount, BigInt minOut) => [
      0xbb,
      0x64,
      0xfa,
      0xcc,
      0x31,
      0xc4,
      0xaf,
      0x14,
      ...u64Le(inAmount),
      ...u64Le(minOut),
    ];

void main() {
  setUpAll(() {
    S.current = const S();
  });

  const usdc = CryptoCurrency(title: "USDC", name: "usdc", decimals: 6);
  const usdt = CryptoCurrency(title: "USDT", name: "usdt", decimals: 6);

  SwapInferenceEngine engineWith({
    Map<String, dynamic> mints = const {},
    Map<String, BigInt> balances = const {},
  }) =>
      SwapInferenceEngine(
        resolver: StubSplResolver(
          byMint: mints.cast(),
          balances: balances,
        ),
        appStore: null,
      );

  group("Path A: netting top-level TransferChecked", () {
    test("an outflow and an inflow become Pay and Receive", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final userUsdt = ataFor(signer, usdtMint);
      const poolUsdc = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM";
      const poolUsdt = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1";

      final accounts = [
        signer,
        tokenProgram,
        jupiter,
        userUsdc,
        usdcMint,
        poolUsdc,
        userUsdt,
        usdtMint,
        poolUsdt,
      ];

      final inference = await engineWith(
        mints: {usdcMint: usdc, usdtMint: usdt},
      ).infer(
        accounts: accounts,
        instructions: _pathAInstructions(accounts),
      );

      expect(inference, isNotNull, reason: "two netted transfers should infer a swap");
      expect(inference!.payAmountFormatted, "2 USDC");
      expect(inference.receiveAmountFormatted, "1.9 USDT");
      expect(inference.directionInferred, isFalse);
      expect(inference.routerName, "Jupiter");
    });
  });

  group("Path B: single router instruction", () {
    test("two tracked ATAs take direction from account order, not balances", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final userUsdt = ataFor(signer, usdtMint);
      final accounts = [signer, jupiter, userUsdc, userUsdt];

      final inference = await engineWith(
        mints: {usdcMint: usdc, usdtMint: usdt},
        // Holding both sides is exactly what breaks a balance heuristic.
        balances: {"USDC": BigInt.from(5000000), "USDT": BigInt.from(9000000)},
      ).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2, 3],
            data: jupiterRouteData(BigInt.from(2500000), BigInt.from(2400000)),
          ),
        ],
      );

      expect(inference, isNotNull);
      expect(inference!.payAmountFormatted, "2.5 USDC");
      expect(inference.receiveAmountFormatted, "2.4 USDT");
      expect(inference.directionInferred, isFalse);
    });

    test("an unknown discriminator refuses to guess amounts", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final userUsdt = ataFor(signer, usdtMint);
      final accounts = [signer, jupiter, userUsdc, userUsdt];

      final inference = await engineWith(
        mints: {usdcMint: usdc, usdtMint: usdt},
      ).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2, 3],
            data: [1, 2, 3, 4, 5, 6, 7, 8, ...u64Le(BigInt.from(99))],
          ),
        ],
      );

      expect(inference, isNull, reason: "wrong bytes must not become a displayed amount");
    });

    test("an unrecognised program with no known router nearby is not called a swap", () async {
      const unknown = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";
      final userUsdc = ataFor(signer, usdcMint);
      final accounts = [signer, unknown, userUsdc];

      final inference = await engineWith(mints: {usdcMint: usdc}).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2],
            data: jupiterRouteData(BigInt.from(1), BigInt.from(1)),
          ),
        ],
      );

      expect(inference, isNull);
    });

    test("more than one non-plumbing instruction is too ambiguous to summarise", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final userUsdt = ataFor(signer, usdtMint);
      const other = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";
      final accounts = [signer, jupiter, userUsdc, userUsdt, other];

      final inference = await engineWith(
        mints: {usdcMint: usdc, usdtMint: usdt},
      ).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2, 3],
            data: jupiterRouteData(BigInt.from(10), BigInt.from(9)),
          ),
          CompiledInstruction(
            programIdIndex: 4,
            accounts: const [],
            data: const [1],
          ),
        ],
      );

      expect(inference, isNull);
    });

    test("a wrap transfer into a temp WSOL account proves SOL is the input", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final tempWsol = ataFor(signer, wsolMint);
      final accounts = [
        signer,
        jupiter,
        systemProgram,
        tokenProgram,
        ataProgram,
        tempWsol,
        userUsdc,
      ];

      final inference = await engineWith(mints: {usdcMint: usdc}).infer(
        accounts: accounts,
        instructions: [
          // create the temp WSOL account
          CompiledInstruction(
            programIdIndex: 4,
            accounts: [0, 5, 0, 5],
            data: const [1],
          ),
          // fund it from the signer: System Transfer of 0.25 SOL
          CompiledInstruction(
            programIdIndex: 2,
            accounts: [0, 5],
            data: [2, 0, 0, 0, ...u64Le(BigInt.from(250000000))],
          ),
          // the swap itself
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [5, 6],
            data: jupiterRouteData(BigInt.from(250000000), BigInt.from(30000000)),
          ),
          // close the temp account
          CompiledInstruction(
            programIdIndex: 3,
            accounts: [5, 0, 0],
            data: const [9],
          ),
        ],
      );

      expect(inference, isNotNull);
      expect(inference!.payAmountFormatted, "0.25 SOL");
      expect(inference.receiveAmountFormatted, contains("USDC"));
      expect(inference.directionInferred, isFalse);
    });

    test("a temp WSOL account with no wrap transfer means SOL is the output", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final tempWsol = ataFor(signer, wsolMint);
      final accounts = [signer, jupiter, tokenProgram, ataProgram, tempWsol, userUsdc];

      final inference = await engineWith(mints: {usdcMint: usdc}).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 3,
            accounts: [0, 4, 0, 4],
            data: const [1],
          ),
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [4, 5],
            data: jupiterRouteData(BigInt.from(4000000), BigInt.from(120000000)),
          ),
          CompiledInstruction(
            programIdIndex: 2,
            accounts: [4, 0, 0],
            data: const [9],
          ),
        ],
      );

      expect(inference, isNotNull);
      expect(inference!.payAmountFormatted, "4 USDC");
      expect(inference.receiveAmountFormatted, "0.12 SOL");
      expect(inference.directionInferred, isFalse);
    });

    test("a permanent WSOL account falls back to balances and says so", () async {
      final userUsdc = ataFor(signer, usdcMint);
      final userWsol = ataFor(signer, wsolMint);
      final accounts = [signer, jupiter, userWsol, userUsdc];

      final inference = await engineWith(
        mints: {usdcMint: usdc},
        balances: {"USDC": BigInt.from(7000000)},
      ).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2, 3],
            data: jupiterRouteData(BigInt.from(7000000), BigInt.from(150000000)),
          ),
        ],
      );

      expect(inference, isNotNull);
      expect(inference!.payAmountFormatted, "7 USDC");
      expect(inference.receiveAmountFormatted, "0.15 SOL");
      expect(inference.directionInferred, isTrue, reason: "balance-derived direction is a guess");
    });

    test("an unresolved mint is reported rather than shown as a bare number", () async {
      const strangeMint = "So11111111111111111111111111111111111111113";
      final userStrange = ataFor(signer, strangeMint);
      final userUsdc = ataFor(signer, usdcMint);
      final accounts = [signer, jupiter, userStrange, userUsdc];

      final inference = await engineWith(
        mints: {
          strangeMint: const CryptoCurrency(title: "", name: "", decimals: 0),
          usdcMint: usdc,
        },
      ).infer(
        accounts: accounts,
        instructions: [
          CompiledInstruction(
            programIdIndex: 1,
            accounts: [2, 3],
            data: jupiterRouteData(BigInt.from(100), BigInt.from(200)),
          ),
        ],
      );

      expect(inference, isNotNull);
      expect(inference!.payAmountFormatted, contains("100"));
    });
  });
}

/// Path A nets top-level TransferChecked instructions: the user's USDC ATA
/// pays a pool account, and a pool account credits the user's USDT ATA.
List<CompiledInstruction> _pathAInstructions(List<String> accounts) {
  final userUsdc = accounts.indexOf(ataFor(signer, usdcMint));
  final userUsdt = accounts.indexOf(ataFor(signer, usdtMint));
  final usdcMintIdx = accounts.indexOf(usdcMint);
  final usdtMintIdx = accounts.indexOf(usdtMint);
  final tokenProgramIdx = accounts.indexOf(tokenProgram);
  final jupiterIdx = accounts.indexOf(jupiter);
  return [
    CompiledInstruction(
      programIdIndex: tokenProgramIdx,
      accounts: [userUsdc, usdcMintIdx, 5],
      data: transferChecked(BigInt.from(2000000), 6),
    ),
    CompiledInstruction(
      programIdIndex: tokenProgramIdx,
      accounts: [8, usdtMintIdx, userUsdt],
      data: transferChecked(BigInt.from(1900000), 6),
    ),
    CompiledInstruction(
      programIdIndex: jupiterIdx,
      accounts: const [],
      data: const [0],
    ),
  ];
}
