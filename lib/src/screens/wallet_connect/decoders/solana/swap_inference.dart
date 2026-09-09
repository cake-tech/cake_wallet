import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class SwapInference {
  SwapInference({
    required this.payAmountFormatted,
    required this.receiveAmountFormatted,
    required this.routerName,
    this.directionInferred = false,
    this.unknownTokens = false,
    this.receiveAmountUnknown = false,
  });

  final String payAmountFormatted;
  final String receiveAmountFormatted;
  final String? routerName;
  final bool directionInferred;
  final bool unknownTokens;
  final bool receiveAmountUnknown;
}

class SwapInferenceEngine {
  SwapInferenceEngine({
    required this.resolver,
    required this.appStore,
  });

  final SplTokenResolver resolver;
  final AppStore? appStore;

  Future<SwapInference?> infer({
    required List<String> accounts,
    required List<CompiledInstruction> instructions,
  }) async {
    if (accounts.isEmpty || instructions.isEmpty) {
      return null;
    }

    final signer = accounts.first;

    final pathA = await _tryTransferPattern(
      accounts: accounts,
      instructions: instructions,
      signer: signer,
    );
    if (pathA != null) {
      return pathA;
    }

    return _tryDirectRouter(
      accounts: accounts,
      instructions: instructions,
      signer: signer,
    );
  }

  Future<SwapInference?> _tryTransferPattern({
    required List<String> accounts,
    required List<CompiledInstruction> instructions,
    required String signer,
  }) async {
    final delta = <String, BigInt>{};
    final ownedAtaCache = <String, String>{};

    String? findRouter;

    for (final ix in instructions) {
      if (ix.programIdIndex >= accounts.length) {
        continue;
      }
      final programId = accounts[ix.programIdIndex];

      final maybeRouter = SolanaProgramIds.swapRouterName(programId);
      if (maybeRouter != null) {
        findRouter = maybeRouter;
      }

      if (!SolanaProgramIds.isTokenProgram(programId)) {
        continue;
      }

      final data = ix.data;
      if (data.isEmpty) {
        continue;
      }
      final tag = data[0];
      if (tag != 12) {
        continue;
      }
      if (data.length < 10) {
        continue;
      }
      if (ix.accounts.length < 3) {
        continue;
      }

      final amount = _readU64Le(data, 1);
      if (amount == null) {
        continue;
      }

      final srcIdx = ix.accounts[0];
      final mintIdx = ix.accounts[1];
      final dstIdx = ix.accounts[2];
      if (srcIdx >= accounts.length || mintIdx >= accounts.length || dstIdx >= accounts.length) {
        continue;
      }

      final mint = accounts[mintIdx];
      final src = accounts[srcIdx];
      final dst = accounts[dstIdx];

      final userAta = ownedAtaCache.putIfAbsent(
        mint,
        () => _deriveAta(owner: signer, mint: mint) ?? "",
      );
      if (userAta.isEmpty) {
        continue;
      }

      if (src == userAta) {
        delta[mint] = (delta[mint] ?? BigInt.zero) - amount;
      } else if (dst == userAta) {
        delta[mint] = (delta[mint] ?? BigInt.zero) + amount;
      }
    }

    if (delta.length < 2) {
      return null;
    }

    String? payMint;
    BigInt payAmount = BigInt.zero;
    String? receiveMint;
    BigInt receiveAmount = BigInt.zero;

    for (final entry in delta.entries) {
      if (entry.value < BigInt.zero) {
        if (payMint != null) {
          return null;
        }
        payMint = entry.key;
        payAmount = -entry.value;
      } else if (entry.value > BigInt.zero) {
        if (receiveMint != null) {
          return null;
        }
        receiveMint = entry.key;
        receiveAmount = entry.value;
      }
    }

    if (payMint == null || receiveMint == null) {
      return null;
    }

    return _buildInference(
      payMint: payMint,
      payAmount: payAmount,
      receiveMint: receiveMint,
      receiveAmount: receiveAmount,
      routerName: findRouter,
      directionInferred: false,
    );
  }

  Future<SwapInference?> _tryDirectRouter({
    required List<String> accounts,
    required List<CompiledInstruction> instructions,
    required String signer,
  }) async {
    CompiledInstruction? main;
    String? mainProgramId;
    String? routerName;
    for (final ix in instructions) {
      if (ix.programIdIndex >= accounts.length) {
        continue;
      }
      final programId = accounts[ix.programIdIndex];
      if (SolanaProgramIds.isPlumbing(programId)) {
        continue;
      }
      if (main != null) {
        return null;
      }
      main = ix;
      mainProgramId = programId;
      routerName = SolanaProgramIds.swapRouterName(programId);
    }
    if (main == null || mainProgramId == null) {
      return null;
    }

    if (routerName == null) {
      for (final idx in main.accounts) {
        if (idx >= accounts.length) {
          continue;
        }
        final r = SolanaProgramIds.swapRouterName(accounts[idx]);
        if (r != null) {
          routerName = r;
          break;
        }
      }
      if (routerName == null) {
        return null;
      }
    }

    final data = main.data;
    final offsets = _swapDataOffsets(data);
    if (offsets == null) {
      return null;
    }
    if (data.length < offsets.$2 + 8) {
      return null;
    }
    final inAmount = _readU64Le(data, offsets.$1);
    final minOut = _readU64Le(data, offsets.$2);
    if (inAmount == null || minOut == null) {
      return null;
    }
    final ceiling = BigInt.two.pow(63);
    if (inAmount >= ceiling || minOut >= ceiling) {
      return null;
    }

    final knownAtas = <String, _MintToken>{};
    final candidateTokens = resolver.trackedAndDefaultTokensByMint();
    for (final entry in candidateTokens.entries) {
      final mint = entry.key;
      if (mint == SolanaProgramIds.wrappedSolMint) {
        continue;
      }
      final ata = _deriveAta(owner: signer, mint: mint);
      if (ata == null) {
        continue;
      }
      knownAtas[ata] = _MintToken(mint, entry.value);
    }
    final userWsolAta = _deriveAta(owner: signer, mint: SolanaProgramIds.wrappedSolMint);

    final foundTokens = <String, CryptoCurrency>{};
    var sawUserWsolAta = false;
    for (final idx in main.accounts) {
      if (idx >= accounts.length) {
        continue;
      }
      final addr = accounts[idx];
      if (userWsolAta != null && addr == userWsolAta) {
        sawUserWsolAta = true;
        continue;
      }
      final hit = knownAtas[addr];
      if (hit != null) {
        foundTokens[hit.mint] = hit.token;
      }
    }

    if (foundTokens.length == 2) {
      String? payMint;
      String? receiveMint;
      for (final idx in main.accounts) {
        if (idx >= accounts.length) {
          continue;
        }
        final hit = knownAtas[accounts[idx]];
        if (hit == null) {
          continue;
        }
        if (payMint == null) {
          payMint = hit.mint;
        } else if (hit.mint != payMint) {
          receiveMint = hit.mint;
          break;
        }
      }
      if (payMint != null && receiveMint != null) {
        return _buildInference(
          payMint: payMint,
          payAmount: inAmount,
          receiveMint: receiveMint,
          receiveAmount: minOut,
          routerName: routerName,
          directionInferred: false,
        );
      }

      final mints = foundTokens.keys.toList();
      final direction = await _resolveTokenDirection(
        mintA: mints[0],
        mintB: mints[1],
      );
      if (direction == null) {
        return null;
      }
      return _buildInference(
        payMint: direction.payMint,
        payAmount: inAmount,
        receiveMint: direction.receiveMint,
        receiveAmount: minOut,
        routerName: routerName,
        directionInferred: true,
      );
    }

    if (foundTokens.length == 1) {
      final tempWsolIndex = _findTempWsolAccountIndex(
        accounts: accounts,
        instructions: instructions,
        mainAccountIndexes: main.accounts,
      );
      final solInvolved = sawUserWsolAta || tempWsolIndex != null;
      if (!solInvolved) {
        return null;
      }

      final mintT = foundTokens.keys.first;
      final tokenT = foundTokens.values.first;
      const wsol = SolanaProgramIds.wrappedSolMint;

      if (tempWsolIndex != null) {
        final wrappedLamports = _findSolWrapTransferLamports(
          accounts: accounts,
          instructions: instructions,
          signerIndex: 0,
          destIndex: tempWsolIndex,
        );

        if (wrappedLamports != null) {
          return _buildInference(
            payMint: wsol,
            payAmount: wrappedLamports,
            receiveMint: mintT,
            receiveAmount: null,
            routerName: routerName,
            directionInferred: false,
          );
        }

        return _buildInference(
          payMint: mintT,
          payAmount: inAmount,
          receiveMint: wsol,
          receiveAmount: minOut,
          routerName: routerName,
          directionInferred: false,
        );
      }

      final tokenBal = resolver.balanceFor(tokenT);
      if (tokenBal > BigInt.zero) {
        return _buildInference(
          payMint: mintT,
          payAmount: inAmount,
          receiveMint: wsol,
          receiveAmount: minOut,
          routerName: routerName,
          directionInferred: true,
        );
      }
      if (_nativeSolBalance() > BigInt.zero) {
        return _buildInference(
          payMint: wsol,
          payAmount: inAmount,
          receiveMint: mintT,
          receiveAmount: minOut,
          routerName: routerName,
          directionInferred: true,
        );
      }
    }

    return null;
  }

  int? _findTempWsolAccountIndex({
    required List<String> accounts,
    required List<CompiledInstruction> instructions,
    required List<int> mainAccountIndexes,
  }) {
    final mainSet = mainAccountIndexes.toSet();
    final createdIndexes = <int>{};
    final closedIndexes = <int>{};
    for (final ix in instructions) {
      if (ix.programIdIndex >= accounts.length) {
        continue;
      }
      final programId = accounts[ix.programIdIndex];
      if (programId == SolanaProgramIds.associatedTokenProgram) {
        if (ix.accounts.length >= 2) {
          createdIndexes.add(ix.accounts[1]);
        }
        continue;
      }
      if (SolanaProgramIds.isTokenProgram(programId)) {
        if (ix.data.isNotEmpty && ix.data[0] == 9 && ix.accounts.isNotEmpty) {
          closedIndexes.add(ix.accounts[0]);
        }
      }
    }
    final tempUsed = createdIndexes.intersection(closedIndexes).intersection(mainSet);
    return tempUsed.isEmpty ? null : tempUsed.first;
  }

  BigInt? _findSolWrapTransferLamports({
    required List<String> accounts,
    required List<CompiledInstruction> instructions,
    required int signerIndex,
    required int destIndex,
  }) {
    for (final ix in instructions) {
      if (ix.programIdIndex >= accounts.length) {
        continue;
      }
      if (accounts[ix.programIdIndex] != SolanaProgramIds.systemProgram) {
        continue;
      }
      if (ix.accounts.length < 2) {
        continue;
      }
      if (ix.accounts[0] != signerIndex || ix.accounts[1] != destIndex) {
        continue;
      }
      if (ix.data.length < 12) {
        continue;
      }
      final tag = (ix.data[0] & 0xff) |
          ((ix.data[1] & 0xff) << 8) |
          ((ix.data[2] & 0xff) << 16) |
          ((ix.data[3] & 0xff) << 24);
      if (tag != 2) {
        continue;
      }
      return _readU64Le(ix.data, 4);
    }
    return null;
  }

  Future<_Direction?> _resolveTokenDirection({
    required String mintA,
    required String mintB,
  }) async {
    final tokenA = await resolver.resolve(mintA);
    final tokenB = await resolver.resolve(mintB);
    final balA = resolver.balanceFor(tokenA);
    final balB = resolver.balanceFor(tokenB);
    if (balA > BigInt.zero && balB == BigInt.zero) {
      return _Direction(payMint: mintA, receiveMint: mintB);
    }
    if (balB > BigInt.zero && balA == BigInt.zero) {
      return _Direction(payMint: mintB, receiveMint: mintA);
    }
    return null;
  }

  BigInt _nativeSolBalance() {
    final wallet = appStore?.wallet;
    if (wallet == null) {
      return BigInt.zero;
    }
    try {
      return wallet.balance[CryptoCurrency.sol]?.available.amount ?? BigInt.zero;
    } catch (e) {
      printV("SwapInferenceEngine: native balance lookup failed: $e");
      return BigInt.zero;
    }
  }

  Future<SwapInference> _buildInference({
    required String payMint,
    required BigInt payAmount,
    required String receiveMint,
    required BigInt? receiveAmount,
    required String? routerName,
    required bool directionInferred,
  }) async {
    final payRender = await _renderAmount(payMint, payAmount);
    final receiveRender = await _renderAmount(receiveMint, receiveAmount);
    return SwapInference(
      payAmountFormatted:
          payRender.amount != null ? "${payRender.amount} ${payRender.symbol}" : payRender.symbol,
      receiveAmountFormatted: receiveRender.amount != null
          ? "${receiveRender.amount} ${receiveRender.symbol}"
          : receiveRender.symbol,
      routerName: routerName,
      directionInferred: directionInferred,
      unknownTokens: payRender.unknown || receiveRender.unknown,
      receiveAmountUnknown: receiveRender.amount == null,
    );
  }

  Future<_Rendered> _renderAmount(String mint, BigInt? rawAmount) async {
    if (mint == SolanaProgramIds.wrappedSolMint) {
      return _Rendered(
        symbol: "SOL",
        amount: rawAmount == null ? null : resolver.formatAmount(rawAmount, 9),
        unknown: false,
      );
    }
    final token = await resolver.resolve(mint);
    final decimals = resolver.decimalsFor(token);
    final symbol = resolver.symbolFor(token, mint);
    final String? amount;
    if (rawAmount == null) {
      amount = null;
    } else if (decimals != null) {
      amount = resolver.formatAmount(rawAmount, decimals);
    } else {
      amount = rawAmount.toString();
    }
    return _Rendered(symbol: symbol, amount: amount, unknown: token == null);
  }

  String? _deriveAta({required String owner, required String mint}) {
    try {
      final pda = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: SolAddress(mint),
        owner: SolAddress(owner),
      );
      return pda.address.address;
    } catch (e) {
      printV("SwapInferenceEngine: ATA derivation failed for $mint: $e");
      return null;
    }
  }

  BigInt? _readU64Le(List<int> data, int offset) {
    if (offset + 8 > data.length) {
      return null;
    }
    var value = BigInt.zero;
    for (var i = 7; i >= 0; i--) {
      value = (value << 8) | BigInt.from(data[offset + i] & 0xff);
    }
    return value;
  }

  static const Map<String, (int, int)> _knownSwapDataOffsets = {
    "bb64facc31c4af14": (8, 16),
    "d19853937cfed8e9": (9, 17),
  };

  (int, int)? _swapDataOffsets(List<int> data) {
    if (data.length < 8) {
      return null;
    }
    final buf = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buf.write((data[i] & 0xff).toRadixString(16).padLeft(2, "0"));
    }
    return _knownSwapDataOffsets[buf.toString()];
  }
}

class _Direction {
  _Direction({required this.payMint, required this.receiveMint});
  final String payMint;
  final String receiveMint;
}

class _Rendered {
  _Rendered({required this.symbol, required this.amount, required this.unknown});
  final String symbol;
  final String? amount;
  final bool unknown;
}

class _MintToken {
  _MintToken(this.mint, this.token);
  final String mint;
  final CryptoCurrency token;
}
