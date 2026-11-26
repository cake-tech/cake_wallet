import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/format_fixed.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class SplTokenDecoder {
  SplTokenDecoder(this.resolver, this.accountFetcher);

  final SplTokenResolver resolver;
  final SolanaAccountFetcher accountFetcher;

  static final _u64Max = (BigInt.one << 64) - BigInt.one;

  static const _authorityTypes = [
    "MintTokens",
    "FreezeAccount",
    "AccountOwner",
    "CloseAccount",
    "TransferFeeConfig",
    "WithheldWithdraw",
    "CloseMint",
    "InterestRate",
    "PermanentDelegate",
    "ConfidentialTransferMint",
    "TransferHookProgramId",
    "ConfidentialTransferFeeConfig",
    "MetadataPointer",
    "GroupPointer",
    "GroupMemberPointer",
    "ScaledUiAmount",
    "Pause",
    "PermissionedBurn",
  ];

  Future<String?> _mintForAccount(String? tokenAccount) async {
    if (tokenAccount == null) {
      return null;
    }

    try {
      final data = (await accountFetcher.fetchAccountsData([tokenAccount]))?.firstOrNull;
      if (data == null || data.length < 32) {
        return null;
      }
      return SolAddress.uncheckBytes(data.sublist(0, 32)).address;
    } catch (e) {
      printV("SplTokenDecoder: mint lookup failed for $tokenAccount: $e");
      return null;
    }
  }

  Future<SolDecodedInstruction?> decode({
    required List<int> data,
    required List<String?> accounts,
    required String wallet,
  }) async {
    final bytes = SolInstructionBytes(data);
    final tag = bytes.u8(0);
    if (tag == null) {
      return null;
    }

    switch (tag) {
      case 3:
        return _decodeTransfer(bytes, accounts);
      case 12:
        return _decodeTransferChecked(bytes, accounts);
      case 4:
        return _decodeApprove(bytes, accounts);
      case 13:
        return _decodeApproveChecked(bytes, accounts);
      case 5:
        return _decodeRevoke(accounts);
      case 6:
        return _decodeSetAuthority(bytes, accounts);
      case 7:
        return _decodeMintTo(bytes, accounts);
      case 8:
        return _decodeBurn(bytes, accounts);
      case 9:
        return _decodeCloseAccount(accounts, wallet);
      case 17:
        return _decodeSyncNative(accounts);
    }
    return null;
  }

  Future<SolDecodedInstruction> _tokenInstruction({
    required String title,
    required String? mint,
    required BigInt amount,
    List<WCDecodedRow> accountRows = const [],
    int? carriedDecimals,
    bool hasMintAccount = true,
    List<String> warnings = const [],
  }) async {
    final token = mint != null && (carriedDecimals == null || resolver.isKnown(mint))
        ? await resolver.resolve(mint)
        : null;
    final decimals = carriedDecimals ?? token?.decimals;
    final amountText = decimals == null ? amount.toString() : formatFixed(amount, decimals);

    return SolDecodedInstruction(
      title: title,
      rows: [
        if (mint != null || hasMintAccount) SolDecodedInstruction.tokenRow(resolver, token, mint),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: mint == null ? amountText : "$amountText ${resolver.symbolFor(token, mint)}",
          kind: WCDecodedRowKind.amount,
        ),
        ...accountRows,
      ],
      warnings: [
        if (decimals == null) S.current.wc_warning_raw_token_amount,
        if (mint != null && !resolver.isKnown(mint)) S.current.wc_warning_unknown_token,
        ...warnings,
      ],
    );
  }

  Future<SolDecodedInstruction?> _decodeTransfer(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    return _tokenInstruction(
      title: S.current.wc_action_transfer,
      mint: await _mintForAccount(accounts[0]),
      hasMintAccount: false,
      amount: amount,
      accountRows: [
        SolDecodedInstruction.accountRow(S.current.from, accounts[0]),
        SolDecodedInstruction.accountRow(S.current.to, accounts[1]),
      ],
    );
  }

  Future<SolDecodedInstruction?> _decodeTransferChecked(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    final decimals = bytes.u8(9);
    if (amount == null || decimals == null || accounts.length < 4) {
      return null;
    }

    return _tokenInstruction(
      title: S.current.wc_action_transfer,
      mint: accounts[1],
      amount: amount,
      carriedDecimals: decimals,
      accountRows: [
        SolDecodedInstruction.accountRow(S.current.from, accounts[0]),
        SolDecodedInstruction.accountRow(S.current.to, accounts[2]),
      ],
    );
  }

  Future<SolDecodedInstruction?> _decodeApprove(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    return _tokenInstruction(
      title: S.current.wc_action_approve,
      mint: await _mintForAccount(accounts[0]),
      hasMintAccount: false,
      amount: amount,
      accountRows: [
        SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts[0]),
        SolDecodedInstruction.accountRow(S.current.wc_approved_spender, accounts[1]),
      ],
      warnings: [if (amount == _u64Max) S.current.wc_warning_unlimited_approval],
    );
  }

  Future<SolDecodedInstruction?> _decodeApproveChecked(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    final decimals = bytes.u8(9);
    if (amount == null || decimals == null || accounts.length < 4) {
      return null;
    }

    return _tokenInstruction(
      title: S.current.wc_action_approve,
      mint: accounts[1],
      amount: amount,
      carriedDecimals: decimals,
      accountRows: [
        SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts[0]),
        SolDecodedInstruction.accountRow(S.current.wc_approved_spender, accounts[2]),
      ],
      warnings: [if (amount == _u64Max) S.current.wc_warning_unlimited_approval],
    );
  }

  SolDecodedInstruction _decodeRevoke(List<String?> accounts) => SolDecodedInstruction(
    title: S.current.wc_action_revoke_approval,
    rows: [
      if (accounts.isNotEmpty)
        SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts.first),
    ],
  );

  SolDecodedInstruction? _decodeSetAuthority(SolInstructionBytes bytes, List<String?> accounts) {
    final authorityType = bytes.u8(1);
    final newAuthorityFlag = bytes.u8(2);
    final newAuthority = newAuthorityFlag == 1 ? bytes.address(3) : null;
    if (authorityType == null || accounts.isEmpty) {
      return null;
    }

    if (newAuthorityFlag != 0 && newAuthority == null) {
      return null;
    }

    return SolDecodedInstruction(
      title: S.current.wc_action_set_authority,
      rows: [
        SolDecodedInstruction.accountRow(S.current.account, accounts[0]),
        WCDecodedRow(
          label: S.current.type,
          value: _authorityTypes.elementAtOrNull(authorityType) ?? authorityType.toString(),
        ),
        if (newAuthority == null)
          WCDecodedRow(label: S.current.wc_new_authority, value: S.current.settings_none)
        else
          SolDecodedInstruction.accountRow(S.current.wc_new_authority, newAuthority),
      ],
      warnings: [S.current.wc_warning_authority_change],
    );
  }

  Future<SolDecodedInstruction?> _decodeMintTo(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    return _tokenInstruction(
      title: S.current.wc_action_mint,
      mint: accounts[0],
      amount: amount,
      accountRows: [SolDecodedInstruction.accountRow(S.current.to, accounts[1])],
    );
  }

  Future<SolDecodedInstruction?> _decodeBurn(
    SolInstructionBytes bytes,
    List<String?> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    return _tokenInstruction(title: S.current.wc_action_burn, mint: accounts[1], amount: amount);
  }

  SolDecodedInstruction _decodeSyncNative(List<String?> accounts) => SolDecodedInstruction(
    title: S.current.wc_action_wrap("SOL"),
    rows: [
      if (accounts.isNotEmpty)
        SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts.first),
    ],
  );

  SolDecodedInstruction _decodeCloseAccount(List<String?> accounts, String wallet) =>
      SolDecodedInstruction(
        title: S.current.wc_action_close_token_account,
        rows: [
          if (accounts.isNotEmpty)
            SolDecodedInstruction.accountRow(S.current.wc_token_account, accounts.first),
          if (accounts.length >= 2) SolDecodedInstruction.accountRow(S.current.to, accounts[1]),
        ],
        warnings: [
          if (accounts.length >= 2 && accounts[1] != wallet) S.current.wc_warning_recipient_not_you,
        ],
      );
}
