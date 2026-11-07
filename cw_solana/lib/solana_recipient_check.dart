import "package:blockchain_utils/blockchain_utils.dart";
import "package:on_chain/solana/solana.dart";

/// Where an SPL token send to the address the user typed should go.
enum SolanaRecipientKind {
  /// A wallet: System-owned, or no account at all yet (a new wallet without SOL, or a vault
  /// PDA that hasn't been funded). Pay into its associated token account, creating it if needed.
  wallet,

  /// An existing token account of the mint being sent. Pay straight into it.
  tokenAccountForMint,

  /// Anything else: a token account of another mint, a mint, or an account owned by some
  /// other program (a multisig's settings account, a stake account, a program). Nothing can
  /// sign for a token account owned by it, so tokens sent there could never move again.
  notAWallet,
}

/// Classifies a send recipient from a single `getAccountInfo` of that address.
class SolanaRecipientCheck {
  /// Size of an SPL token account (Token and Token-2022 without extensions).
  static const tokenAccountSize = 165;

  /// Token-2022 accounts with extensions store their account type right after the base layout.
  static const _accountTypeIndex = tokenAccountSize;
  static const _accountTypeAccount = 2;

  /// Bytes of account data [classify] reads: the mint (bytes 0-31) and the account type byte.
  static const dataSliceLength = _accountTypeIndex + 1;

  static SolanaRecipientKind classify({
    required SolanaAccountInfo? info,
    required SolAddress mint,
    required SolAddress tokenProgramId,
  }) {
    if (info == null) {
      return SolanaRecipientKind.wallet;
    }

    if (info.owner == SystemProgramConst.programId) {
      return SolanaRecipientKind.wallet;
    }

    if (info.owner == tokenProgramId && _isTokenAccountOfMint(info, mint)) {
      return SolanaRecipientKind.tokenAccountForMint;
    }

    return SolanaRecipientKind.notAWallet;
  }

  static bool _isTokenAccountOfMint(SolanaAccountInfo info, SolAddress mint) {
    final List<int> data;
    try {
      data = info.toBytesData();
    } catch (_) {
      return false;
    }
    if (data.length < 32) {
      return false;
    }

    final isTokenAccount = info.space == tokenAccountSize ||
        (info.owner == SPLTokenProgramConst.token2022ProgramId &&
            info.space > tokenAccountSize &&
            data.length > _accountTypeIndex &&
            data[_accountTypeIndex] == _accountTypeAccount);

    return isTokenAccount && BytesUtils.bytesEqual(data.sublist(0, 32), mint.toBytes());
  }
}
