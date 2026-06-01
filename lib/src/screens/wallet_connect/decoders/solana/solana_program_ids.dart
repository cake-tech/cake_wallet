class SolanaProgramIds {
  static const systemProgram = '11111111111111111111111111111111';

  static const tokenProgram = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
  static const token2022Program = 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb';
  static const associatedTokenProgram = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';

  static const memoV1 = 'Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo';
  static const memoV2 = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr';

  static const computeBudget = 'ComputeBudget111111111111111111111111111111';

  static const jupiterV6 = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
  static const jupiterV4 = 'JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB';

  static const raydiumAmmV4 = '675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8';
  static const raydiumCpmm = 'CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C';
  static const raydiumClmm = 'CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK';

  static const orcaWhirlpool = 'whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc';

  static const splTokenSwap = 'SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8';

  static bool isTokenProgram(String programId) =>
      programId == tokenProgram || programId == token2022Program;

  static bool isMemoProgram(String programId) => programId == memoV1 || programId == memoV2;

  static String? swapRouterName(String programId) {
    switch (programId) {
      case jupiterV6:
      case jupiterV4:
        return 'Jupiter';
      case raydiumAmmV4:
      case raydiumCpmm:
      case raydiumClmm:
        return 'Raydium';
      case orcaWhirlpool:
        return 'Orca';
      default:
        return null;
    }
  }

  static bool isInternal(String programId) {
    return programId == computeBudget;
  }
}
