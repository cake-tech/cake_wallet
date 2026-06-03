import 'dart:convert';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/ata_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/memo_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart';
import 'package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:on_chain/solana/solana.dart';

class SolanaRequestDecoder {
  SolanaRequestDecoder(AppStore appStore) : _resolver = SplTokenResolver(appStore) {
    _systemDecoder = SystemProgramDecoder(_resolver);
    _splDecoder = SplTokenDecoder(_resolver);
    _ataDecoder = AtaDecoder(_resolver);
    _memoDecoder = MemoDecoder();
  }

  final SplTokenResolver _resolver;
  late final SystemProgramDecoder _systemDecoder;
  late final SplTokenDecoder _splDecoder;
  late final AtaDecoder _ataDecoder;
  late final MemoDecoder _memoDecoder;

  Future<WCDecodedRequest> decodeSignMessage(String messageBase58) async {
    String decoded;
    try {
      final bytes = _decodeBase58(messageBase58);
      decoded = utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      printV('SolanaRequestDecoder: sign-message decode failed: $e');
      decoded = messageBase58;
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_message,
      rows: [WCDecodedRow(label: S.current.wc_message_label, value: decoded)],
      hideTo: true,
      hideZeroValue: true,
    );
  }

  Future<WCDecodedRequest> decodeTransaction(Map<String, dynamic> params) async {
    final raw = const JsonEncoder.withIndent('  ').convert(params);
    final transaction = _deserialize(params);
    if (transaction == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_transaction,
        warnings: [S.current.wc_warning_decode_failed],
        rawFallback: raw,
        hideTo: true,
        hideZeroValue: true,
      );
    }

    final accounts = transaction.message.accountKeys.map((a) => a.address).toList();
    final instructions = transaction.message.compiledInstructions;

    final perInstructionRows = <WCDecodedRow>[];
    final warnings = <String>{};
    final routerNames = <String>{};
    String? overallTitle;

    for (var i = 0; i < instructions.length; i++) {
      final compiled = instructions[i];
      if (compiled.programIdIndex >= accounts.length) continue;
      final programId = accounts[compiled.programIdIndex];

      if (SolanaProgramIds.isInternal(programId)) continue;

      final swapName = SolanaProgramIds.swapRouterName(programId);
      if (swapName != null) {
        routerNames.add(swapName);
        continue;
      }

      final hasUnresolvedAccounts =
          compiled.accounts.any((idx) => idx >= accounts.length);
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
          perInstructionRows.add(WCDecodedRow(
            label: S.current.wc_instruction_n((i + 1).toString()),
            value: '${S.current.wc_program}: ${_resolver.shortAddress(programId)}',
          ));
          warnings.add(S.current.wc_warning_unknown_instruction);
          continue;
        }

        overallTitle ??= decoded.title;
        perInstructionRows.add(WCDecodedRow(
          label: S.current.wc_instruction_n((i + 1).toString()),
          value: decoded.title,
        ));
        perInstructionRows.addAll(decoded.rows);
        warnings.addAll(decoded.warnings);
      } catch (e, s) {
        printV('SolanaRequestDecoder: instruction $i decode failed: $e\n$s');
        perInstructionRows.add(WCDecodedRow(
          label: S.current.wc_instruction_n((i + 1).toString()),
          value: S.current.wc_decode_failed,
        ));
        warnings.add(S.current.wc_warning_decode_failed);
      }
    }

    if (routerNames.isNotEmpty) {
      final name = routerNames.first;
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_swap,
        actionSubtitle: S.current.wc_via(name),
        rows: perInstructionRows,
        warnings: [
          S.current.wc_warning_swap_amounts_estimated,
          ...warnings,
        ],
        rawFallback: raw,
        hideTo: true,
        hideZeroValue: true,
      );
    }

    return WCDecodedRequest(
      actionTitle: overallTitle ?? S.current.wc_action_sign_transaction,
      rows: perInstructionRows,
      warnings: warnings.toList(),
      rawFallback: raw,
      hideTo: true,
      hideZeroValue: true,
    );
  }

  Future<WCDecodedRequest> decodeAllTransactions(Map<String, dynamic> params) async {
    final raw = const JsonEncoder.withIndent('  ').convert(params);
    final transactions = (params['transactions'] as List?)?.cast<String>() ?? const [];
    if (transactions.isEmpty) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_all_transactions,
        warnings: [S.current.wc_warning_decode_failed],
        rawFallback: raw,
        hideTo: true,
        hideZeroValue: true,
      );
    }

    final rows = <WCDecodedRow>[];
    final warnings = <String>{};
    for (var i = 0; i < transactions.length; i++) {
      final decoded = await decodeTransaction({'transaction': transactions[i]});
      rows.add(WCDecodedRow(
        label: S.current.wc_transaction_n((i + 1).toString()),
        value: decoded.actionTitle,
      ));
      rows.addAll(decoded.rows);
      warnings.addAll(decoded.warnings);
    }
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_sign_all_transactions,
      actionSubtitle: S.current.wc_transactions_count(transactions.length.toString()),
      rows: rows,
      warnings: warnings.toList(),
      rawFallback: raw,
      hideTo: true,
      hideZeroValue: true,
    );
  }

  SolanaTransaction? _deserialize(Map<String, dynamic> params) {
    try {
      if (params.containsKey('transaction')) {
        final transactionStr = params['transaction'] as String;
        return SolanaTransaction.deserialize(base64.decode(transactionStr));
      }
      if (params.containsKey('feePayer') && params.containsKey('instructions')) {
        final feePayer = params['feePayer'].toString();
        final recentBlockHash = params['recentBlockhash']?.toString() ?? '';
        final instructionsList = params['instructions'] as List<dynamic>;
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
      printV('SolanaRequestDecoder: deserialize failed: $e\n$s');
    }
    return null;
  }

  TransactionInstruction _instructionFromJson(Map<String, dynamic> json) {
    final programId = json['programId'] as String;
    final data = (json['data'] as List).map((e) => e as int).toList();
    final keys = (json['keys'] as List).map((k) {
      final m = k as Map<String, dynamic>;
      return AccountMeta(
        publicKey: SolAddress(m['pubkey'] as String),
        isWritable: m['isWritable'] as bool? ?? false,
        isSigner: m['isSigner'] as bool? ?? false,
      );
    }).toList();
    return TransactionInstruction.fromBytes(
      programId: SolAddress(programId),
      instructionBytes: data,
      keys: keys,
    );
  }

  List<int> _decodeBase58(String input) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    var num = BigInt.zero;
    final base = BigInt.from(58);
    for (final ch in input.split('')) {
      final idx = alphabet.indexOf(ch);
      if (idx < 0) throw const FormatException('Invalid base58 character');
      num = num * base + BigInt.from(idx);
    }
    final bytes = <int>[];
    while (num > BigInt.zero) {
      bytes.insert(0, (num % BigInt.from(256)).toInt());
      num = num ~/ BigInt.from(256);
    }
    for (final ch in input.split('')) {
      if (ch == '1') {
        bytes.insert(0, 0);
      } else {
        break;
      }
    }
    return bytes;
  }
}
