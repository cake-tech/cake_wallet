import "dart:convert";

import "package:blockchain_utils/base58/base58.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/alt_lookup.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/ata_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/memo_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/swap_inference.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class SolanaRequestDecoder {
  SolanaRequestDecoder(AppStore? appStore) : _resolver = SplTokenResolver(appStore) {
    _fetcher = SolanaAccountFetcher(appStore);
    _altLookup = AltLookup(_fetcher);
    _systemDecoder = SystemProgramDecoder(_resolver);
    _splDecoder = SplTokenDecoder(_resolver, _fetcher);
    _ataDecoder = AtaDecoder(_resolver);
    _memoDecoder = MemoDecoder();
    _swapInference = SwapInferenceEngine(resolver: _resolver, appStore: appStore);
  }

  static const _lamportsPerSignature = 5000;

  final SplTokenResolver _resolver;
  late final SolanaAccountFetcher _fetcher;
  late final AltLookup _altLookup;
  late final SystemProgramDecoder _systemDecoder;
  late final SplTokenDecoder _splDecoder;
  late final AtaDecoder _ataDecoder;
  late final MemoDecoder _memoDecoder;
  late final SwapInferenceEngine _swapInference;

  Future<WCDecodedRequest> decodeSignMessage(String messageBase58) async {
    String decoded;
    try {
      final bytes = Base58Decoder.decode(messageBase58);
      decoded = utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      printV("SolanaRequestDecoder: sign-message decode failed: $e");
      decoded = messageBase58;
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_message,
      rows: [WCDecodedRow(label: S.current.wc_message_label, value: decoded)],
      hideTo: true,
      hideValue: true,
    );
  }

  Future<WCDecodedRequest> decodeTransaction(Map<String, dynamic> params) async {
    final raw = const JsonEncoder.withIndent("  ").convert(params);
    final transaction = transactionFromParams(params);
    if (transaction == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_transaction,
        warnings: [S.current.wc_warning_decode_failed],
        rawFallback: raw,
        hideTo: true,
        hideValue: true,
      );
    }

    final accounts = await _altLookup.resolveAccountKeys(transaction);
    final instructions = transaction.message.compiledInstructions;
    final feeRow = _feeRow(transaction, accounts);

    final perInstructionRows = <WCDecodedRow>[];
    final warnings = <String>{};
    final routerNames = <String>{};
    String? overallTitle;

    for (var i = 0; i < instructions.length; i++) {
      final compiled = instructions[i];
      if (compiled.programIdIndex >= accounts.length) {
        continue;
      }
      final programId = accounts[compiled.programIdIndex];

      if (SolanaProgramIds.isInternal(programId)) {
        continue;
      }

      final swapName = SolanaProgramIds.swapRouterName(programId);
      if (swapName != null) {
        routerNames.add(swapName);
        continue;
      }

      final hasUnresolvedAccounts = compiled.accounts.any((idx) => idx >= accounts.length);
      if (hasUnresolvedAccounts) {
        warnings.add(S.current.wc_warning_unresolved_accounts);
      }
      final accountAddresses = compiled.accounts
          .where((idx) => idx < accounts.length)
          .map((idx) => accounts[idx])
          .toList();

      try {
        SolDecodedInstruction? decoded;
        if (programId == SolanaProgramIds.systemProgram) {
          decoded = _systemDecoder.decode(data: compiled.data, accounts: accountAddresses);
        } else if (SolanaProgramIds.isTokenProgram(programId)) {
          decoded = await _splDecoder.decode(
            data: compiled.data,
            accounts: accountAddresses,
          );
        } else if (programId == SolanaProgramIds.associatedTokenProgram) {
          decoded = await _ataDecoder.decode(
            data: compiled.data,
            accounts: accountAddresses,
          );
        } else if (SolanaProgramIds.isMemoProgram(programId)) {
          decoded = _memoDecoder.decode(compiled.data);
        }

        if (decoded == null) {
          perInstructionRows.add(
            WCDecodedRow(
              label: S.current.wc_instruction_n((i + 1).toString()),
              value: "${S.current.wc_program}: ${_resolver.shortAddress(programId)}",
            ),
          );
          warnings.add(S.current.wc_warning_unknown_instruction);
          continue;
        }

        overallTitle ??= decoded.title;
        perInstructionRows.add(
          WCDecodedRow(
            label: S.current.wc_instruction_n((i + 1).toString()),
            value: decoded.title,
          ),
        );
        perInstructionRows.addAll(decoded.rows);
        warnings.addAll(decoded.warnings);
      } catch (e, s) {
        printV("SolanaRequestDecoder: instruction $i decode failed: $e\n$s");
        perInstructionRows.add(
          WCDecodedRow(
            label: S.current.wc_instruction_n((i + 1).toString()),
            value: S.current.wc_decode_failed,
          ),
        );
        warnings.add(S.current.wc_warning_decode_failed);
      }
    }

    final inferredSwap = await _inferSwap(transaction, accounts);

    if (inferredSwap != null) {
      final subtitleSource = inferredSwap.routerName ?? routerNames.firstOrNull;
      final swapRows = <WCDecodedRow>[
        WCDecodedRow(
          label: S.current.wc_swap_from,
          value: inferredSwap.payAmountFormatted,
          kind: WCDecodedRowKind.amount,
        ),
        WCDecodedRow(
          label:
              inferredSwap.receiveAmountUnknown ? S.current.wc_swap_to : S.current.wc_swap_to_min,
          value: inferredSwap.receiveAmountFormatted,
          kind: WCDecodedRowKind.amount,
        ),
      ];

      return WCDecodedRequest(
        actionTitle: S.current.wc_action_swap,
        actionSubtitle: subtitleSource != null ? S.current.wc_via(subtitleSource) : null,
        rows: [...swapRows, if (feeRow != null) feeRow],
        detailRows: perInstructionRows,
        warnings: [
          S.current.wc_warning_swap_amounts_estimated,
          if (inferredSwap.directionInferred) S.current.wc_warning_swap_direction_inferred,
          if (inferredSwap.unknownTokens) S.current.wc_warning_unknown_token,
          ...warnings,
        ],
        rawFallback: raw,
        hideTo: true,
        hideValue: true,
      );
    }

    if (routerNames.isNotEmpty) {
      final name = routerNames.first;
      final hasAmounts = perInstructionRows.isNotEmpty;
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_swap,
        actionSubtitle: S.current.wc_via(name),
        rows: [...perInstructionRows, if (feeRow != null) feeRow],
        warnings: [
          if (hasAmounts) S.current.wc_warning_swap_amounts_estimated,
          if (!hasAmounts) S.current.wc_warning_swap_amounts_unavailable,
          ...warnings,
        ],
        rawFallback: raw,
        hideTo: true,
        hideValue: true,
      );
    }

    return WCDecodedRequest(
      actionTitle: overallTitle ?? S.current.wc_action_sign_transaction,
      rows: [...perInstructionRows, if (feeRow != null) feeRow],
      warnings: warnings.toList(),
      rawFallback: raw,
      hideTo: true,
      hideValue: true,
    );
  }

  WCDecodedRow? _feeRow(SolanaTransaction transaction, List<String> accounts) {
    try {
      BigInt? unitPrice;
      int? unitLimit;
      for (final instruction in transaction.message.compiledInstructions) {
        if (instruction.programIdIndex >= accounts.length) {
          continue;
        }
        if (accounts[instruction.programIdIndex] != SolanaProgramIds.computeBudget) {
          continue;
        }
        final bytes = SolInstructionBytes(instruction.data);
        final tag = bytes.u8(0);
        if (tag == 2) {
          unitLimit = bytes.u32Le(1);
        }
        if (tag == 3) {
          unitPrice = bytes.u64Le(1);
        }
      }

      final signatures = transaction.message.header.numRequiredSignatures;
      var lamports = BigInt.from(signatures * _lamportsPerSignature);
      if (unitPrice != null && unitLimit != null && unitPrice > BigInt.zero && unitLimit > 0) {
        final micro = unitPrice * BigInt.from(unitLimit);
        lamports += (micro + BigInt.from(999999)) ~/ BigInt.from(1000000);
      }

      return WCDecodedRow(
        label: S.current.wc_network_fee,
        value: "~ ${_resolver.formatSol(lamports)} SOL",
        kind: WCDecodedRowKind.amount,
      );
    } catch (e) {
      printV("SolanaRequestDecoder: fee estimate failed: $e");
      return null;
    }
  }

  Future<SwapInference?> _inferSwap(SolanaTransaction transaction, List<String> accounts) async {
    try {
      return await _swapInference.infer(
        accounts: accounts,
        instructions: transaction.message.compiledInstructions,
      );
    } catch (e, s) {
      printV("SolanaRequestDecoder: swap inference failed: $e\n$s");
      return null;
    }
  }

  Future<WCDecodedRequest> decodeAllTransactions(Map<String, dynamic> params) async {
    final raw = const JsonEncoder.withIndent("  ").convert(params);
    final transactions = (params["transactions"] as List?)?.cast<String>() ?? const [];
    if (transactions.isEmpty) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_all_transactions,
        warnings: [S.current.wc_warning_decode_failed],
        rawFallback: raw,
        hideTo: true,
        hideValue: true,
      );
    }

    final rows = <WCDecodedRow>[];
    final detailRows = <WCDecodedRow>[];
    final warnings = <String>{};
    for (var i = 0; i < transactions.length; i++) {
      final decoded = await decodeTransaction({"transaction": transactions[i]});
      final label = S.current.wc_transaction_n((i + 1).toString());
      rows.add(WCDecodedRow(label: label, value: decoded.actionTitle));
      rows.addAll(decoded.rows);
      warnings.addAll(decoded.warnings);
      if (decoded.detailRows.isNotEmpty) {
        detailRows.add(WCDecodedRow(label: label, value: decoded.actionTitle));
        detailRows.addAll(decoded.detailRows);
      }
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_all_transactions,
      actionSubtitle: S.current.wc_transactions_count(transactions.length.toString()),
      rows: rows,
      detailRows: detailRows,
      warnings: warnings.toList(),
      rawFallback: raw,
      hideTo: true,
      hideValue: true,
    );
  }

  SolanaTransaction? transactionFromParams(Map<String, dynamic> params) {
    try {
      if (params.containsKey("transaction")) {
        final transactionStr = params["transaction"] as String;
        return SolanaTransaction.deserialize(base64.decode(transactionStr));
      }
      if (params.containsKey("feePayer") && params.containsKey("instructions")) {
        final feePayer = params["feePayer"].toString();
        final recentBlockHash = params["recentBlockhash"]?.toString() ?? "";
        final instructionsList = params["instructions"] as List<dynamic>;
        final instructions = instructionsList
            .map((json) => _instructionFromJson(json as Map<String, dynamic>))
            .toList();
        return SolanaTransaction(
          payerKey: SolAddress(feePayer),
          instructions: instructions,
          recentBlockhash: SolAddress(recentBlockHash),
        );
      }
    } catch (e, s) {
      printV("SolanaRequestDecoder: deserialize failed: $e\n$s");
    }
    return null;
  }

  TransactionInstruction _instructionFromJson(Map<String, dynamic> json) {
    final programId = json["programId"] as String;
    final data = (json["data"] as List).map((e) => e as int).toList();
    final keys = (json["keys"] as List).map((k) {
      final m = k as Map<String, dynamic>;
      return AccountMeta(
        publicKey: SolAddress(m["pubkey"] as String),
        isWritable: m["isWritable"] as bool,
        isSigner: m["isSigner"] as bool,
      );
    }).toList();
    return TransactionInstruction.fromBytes(
      programId: SolAddress(programId),
      instructionBytes: data,
      keys: keys,
    );
  }
}
