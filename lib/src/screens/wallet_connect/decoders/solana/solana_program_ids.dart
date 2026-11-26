class SolanaProgramIds {
  static const systemProgram = "11111111111111111111111111111111";

  static const tokenProgram = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
  static const token2022Program = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb";
  static const associatedTokenProgram = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";

  static const memoV1 = "Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo";
  static const memoV2 = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr";

  static const computeBudget = "ComputeBudget111111111111111111111111111111";

  static const ed25519SigVerify = "Ed25519SigVerify111111111111111111111111111";
  static const keccakSecp256k1 = "KeccakSecp256k11111111111111111111111111111";
  static const secp256r1SigVerify = "Secp256r1SigVerify1111111111111111111111111";

  static const wrappedSolMint = "So11111111111111111111111111111111111111112";

  static const jupiterV6 = "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4";
  static const jupiterV4 = "JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB";
  static const jupiterLimitOrderV2 = "j1o2qRpjcyUwEvwtcfhEQefh773ZgjxcVRry7LDqg5X";
  static const jupiterDca = "DCA265Vj8a9CEuX1eb1LWRnDT7uK6q1xMipnNyatn23M";

  static const raydiumAmmV4 = "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8";
  static const raydiumCpmm = "CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C";
  static const raydiumClmm = "CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK";

  static const orcaWhirlpool = "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc";

  static const meteoraDlmm = "LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo";

  static const phoenixV1 = "PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY";

  static const splTokenSwap = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8";

  static bool isTokenProgram(String programId) =>
      programId == tokenProgram || programId == token2022Program;

  static bool isMemoProgram(String programId) => programId == memoV1 || programId == memoV2;

  static const _routerNames = {
    jupiterV6: "Jupiter",
    jupiterV4: "Jupiter",
    jupiterLimitOrderV2: "Jupiter",
    jupiterDca: "Jupiter",
    raydiumAmmV4: "Raydium",
    raydiumCpmm: "Raydium",
    raydiumClmm: "Raydium",
    orcaWhirlpool: "Orca",
    meteoraDlmm: "Meteora",
    phoenixV1: "Phoenix",
    splTokenSwap: "SPL Token Swap",
  };

  static String displayName(String programId) {
    final routerName = _routerNames[programId];
    return routerName == null ? programId : "$routerName ($programId)";
  }

  static bool isSignatureVerifier(String programId) =>
      programId == ed25519SigVerify ||
      programId == keccakSecp256k1 ||
      programId == secp256r1SigVerify;
}
