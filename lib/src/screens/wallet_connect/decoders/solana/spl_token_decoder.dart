import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class SplTokenDecoder {
  SplTokenDecoder(this.resolver, this.accountFetcher);

  final SplTokenResolver resolver;
  final SolanaAccountFetcher accountFetcher;

  Future<CryptoCurrency?> _tokenForAccount(String tokenAccount) async {
    try {
      final data = await accountFetcher.fetchAccountData(tokenAccount);
      if (data == null || data.length < 32) {
        return null;
      }
      final mint = SolAddress.uncheckBytes(data.sublist(0, 32)).address;
      return resolver.resolve(mint);
    } catch (e) {
      printV("SplTokenDecoder: mint lookup failed for $tokenAccount: $e");
      return null;
    }
  }

  Future<SolDecodedInstruction?> decode({
    required List<int> data,
    required List<String> accounts,
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
      case 7:
        return _decodeMintTo(bytes, accounts);
      case 8:
        return _decodeBurn(bytes, accounts);
      case 9:
        return _decodeCloseAccount(accounts);
    }
    return null;
  }

  Future<SolDecodedInstruction?> _decodeTransfer(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    final token = await _tokenForAccount(accounts[0]);
    final symbol = token == null ? null : resolver.symbolFor(token, "");
    final decimals = resolver.decimalsFor(token);

    return SolDecodedInstruction(
      title: S.current.wc_action_transfer,
      rows: [
        if (symbol != null) WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: decimals == null
              ? amount.toString()
              : "${resolver.formatAmount(amount, decimals)} $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.from,
          value: accounts[0],
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: accounts[1],
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_raw_token_amount],
    );
  }

  Future<SolDecodedInstruction?> _decodeTransferChecked(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    final decimals = bytes.u8(9);
    if (amount == null || decimals == null || accounts.length < 4) {
      return null;
    }
    final mint = accounts[1];
    final token = await resolver.resolve(mint);
    final tokenDecimals = resolver.decimalsFor(token) ?? decimals;
    final amountStr = resolver.formatAmount(amount, tokenDecimals);
    final symbol = resolver.symbolFor(token, mint);
    return SolDecodedInstruction(
      title: S.current.wc_action_transfer,
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.from,
          value: accounts[0],
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: accounts[2],
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_unknown_token],
    );
  }

  Future<SolDecodedInstruction?> _decodeApprove(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }

    final token = await _tokenForAccount(accounts[0]);
    final symbol = token == null ? null : resolver.symbolFor(token, "");
    final decimals = resolver.decimalsFor(token);

    return SolDecodedInstruction(
      title: S.current.wc_action_approve,
      rows: [
        if (symbol != null) WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: decimals == null
              ? amount.toString()
              : "${resolver.formatAmount(amount, decimals)} $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.wc_spender,
          value: accounts[1],
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_raw_token_amount],
    );
  }

  Future<SolDecodedInstruction?> _decodeApproveChecked(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    final decimals = bytes.u8(9);
    if (amount == null || decimals == null || accounts.length < 4) {
      return null;
    }
    final mint = accounts[1];
    final token = await resolver.resolve(mint);
    final tokenDecimals = resolver.decimalsFor(token) ?? decimals;
    final amountStr = resolver.formatAmount(amount, tokenDecimals);
    final symbol = resolver.symbolFor(token, mint);
    return SolDecodedInstruction(
      title: S.current.wc_action_approve,
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.wc_spender,
          value: accounts[2],
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (token == null) S.current.wc_warning_unknown_token],
    );
  }

  SolDecodedInstruction _decodeRevoke(List<String> accounts) => SolDecodedInstruction(
        title: S.current.wc_action_revoke_approval,
        rows: [
          if (accounts.isNotEmpty)
            WCDecodedRow(
              label: S.current.wc_token_account,
              value: accounts.first,
              kind: WCDecodedRowKind.address,
            ),
        ],
      );

  Future<SolDecodedInstruction?> _decodeMintTo(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }
    final mint = accounts[0];
    final token = await resolver.resolve(mint);
    final decimals = resolver.decimalsFor(token);
    final amountStr =
        decimals == null ? amount.toString() : resolver.formatAmount(amount, decimals);
    final symbol = resolver.symbolFor(token, mint);
    return SolDecodedInstruction(
      title: S.current.wc_action_mint,
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label: S.current.to,
          value: accounts[1],
          kind: WCDecodedRowKind.address,
        ),
      ],
      warnings: [if (decimals == null) S.current.wc_warning_raw_token_amount],
    );
  }

  Future<SolDecodedInstruction?> _decodeBurn(
    SolInstructionBytes bytes,
    List<String> accounts,
  ) async {
    final amount = bytes.u64Le(1);
    if (amount == null || accounts.length < 3) {
      return null;
    }
    final mint = accounts[1];
    final token = await resolver.resolve(mint);
    final decimals = resolver.decimalsFor(token);
    final amountStr =
        decimals == null ? amount.toString() : resolver.formatAmount(amount, decimals);
    final symbol = resolver.symbolFor(token, mint);
    return SolDecodedInstruction(
      title: S.current.wc_action_burn,
      rows: [
        WCDecodedRow(label: S.current.wc_token, value: symbol),
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $symbol",
          kind: WCDecodedRowKind.amount,
        ),
      ],
      warnings: [if (decimals == null) S.current.wc_warning_raw_token_amount],
    );
  }

  SolDecodedInstruction _decodeCloseAccount(List<String> accounts) => SolDecodedInstruction(
        title: S.current.wc_action_close_token_account,
        rows: [
          if (accounts.isNotEmpty)
            WCDecodedRow(
              label: S.current.wc_token_account,
              value: accounts.first,
              kind: WCDecodedRowKind.address,
            ),
        ],
      );
}
