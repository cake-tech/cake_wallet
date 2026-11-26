import "dart:async";
import "dart:convert";
import "dart:math";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/alt_lookup.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/ata_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/memo_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/sol_instruction_bytes.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_account_fetcher.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/spl_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/system_program_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:on_chain/solana/solana.dart";

class SolanaRequestDecoder {
  SolanaRequestDecoder(this._appStore);

  static const _lamportsPerSignature = 5000;

  static const _maxTransactionChars = 1644;

  static const _lookupBudget = Duration(seconds: 10);

  static const _builtinInstructionComputeUnits = 3000;
  static const _otherInstructionComputeUnits = 200000;
  static const _maxComputeUnits = 1400000;

  static const _setUnitLimitTag = 2;
  static const _setUnitPriceTag = 3;

  static final _highFeeLamports = BigInt.from(50000000);

  final AppStore? _appStore;

  WCDecodedRequest decodeSignMessage(List<int> messageBytes) {
    if (_isTransactionMessage(messageBytes)) {
      throw const FormatException("solana_signMessage payload is a transaction message");
    }

    final text = utf8.decode(messageBytes);
    if (!BytesUtils.bytesEqual(utf8.encode(text), messageBytes)) {
      throw const FormatException("solana_signMessage text is not the bytes that get signed");
    }

    return WCDecodedRequest.signMessage(text);
  }

  bool _isTransactionMessage(List<int> bytes) {
    try {
      return BytesUtils.bytesEqual(VersionedMessage.fromBuffer(bytes).serialize(), bytes);
    } catch (_) {
      return false;
    }
  }

  Future<WCDecodedRequest> decodeTransaction(
    Map<String, dynamic> params, {
    required String walletAddress,
  }) async {
    final raw = const JsonEncoder.withIndent("  ").convert(params);
    final transaction = transactionFromParams(params);
    if (transaction == null) {
      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_transaction,
        warnings: [S.current.wc_warning_decode_failed],
        rawFallback: raw,
      );
    }

    final decoded = await _withLookups(
      (lookups) => _decodeTransaction(transaction, walletAddress: walletAddress, lookups: lookups),
    );
    return decoded.copyWith(rawFallback: raw);
  }

  Future<WCDecodedRequest> _withLookups(
    Future<WCDecodedRequest> Function(_RequestLookups lookups) decode,
  ) async {
    final budget = SolanaLookupBudget();
    final budgetTimer = Timer(_lookupBudget, budget.markSpent);
    try {
      return await decode(_RequestLookups(_appStore, budget));
    } finally {
      budgetTimer.cancel();
    }
  }

  Future<WCDecodedRequest> _decodeTransaction(
    SolanaTransaction transaction, {
    required String walletAddress,
    required _RequestLookups lookups,
  }) async {
    final accounts = await AltLookup(lookups.fetcher).resolveAccountKeys(transaction);
    final instructions = transaction.message.compiledInstructions;

    final instructionRows = <WCDecodedRow>[];
    final warnings = <String>{};
    String? decodedTitle;
    var shownInstructions = 0;

    for (var index = 0; index < instructions.length; index++) {
      final compiled = instructions[index];
      final programId = compiled.programIdIndex < accounts.length
          ? accounts[compiled.programIdIndex]
          : null;
      if (programId == SolanaProgramIds.computeBudget) {
        continue;
      }

      shownInstructions++;
      final accountAddresses = [
        for (final accountIndex in compiled.accounts)
          accountIndex < accounts.length ? accounts[accountIndex] : null,
      ];
      if (programId == null || accountAddresses.contains(null)) {
        warnings.add(S.current.wc_warning_unresolved_accounts);
      }

      if (index == 0 &&
          programId == SolanaProgramIds.systemProgram &&
          SolInstructionBytes(compiled.data).u32Le(0) ==
              SystemProgramDecoder.advanceNonceAccountTag) {
        warnings.add(S.current.wc_warning_durable_nonce);
        final authority = accountAddresses.elementAtOrNull(
          SystemProgramDecoder.nonceAuthorityPosition,
        );
        if (authority != walletAddress) {
          warnings.add(S.current.wc_warning_nonce_authority_not_you);
        }
      }

      final decoded = programId == null
          ? null
          : await _decodeInstruction(
              programId,
              compiled.data,
              accountAddresses,
              walletAddress,
              lookups,
            );
      if (decoded != null) {
        decodedTitle = decoded.title;
        warnings.addAll(decoded.warnings);
      }

      if (decoded == null && programId != null) {
        warnings.add(S.current.wc_warning_unknown_instruction);
      }

      final program = programId == null
          ? S.current.wc_decode_failed
          : SolanaProgramIds.displayName(programId);
      instructionRows.add(
        WCDecodedRow(
          label: S.current.wc_instruction_n((index + 1).toString()),
          value: decoded?.title ?? "${S.current.wc_program}: $program",
        ),
      );
      instructionRows.addAll(decoded?.rows ?? const []);
    }

    final feeLamports = _feeLamports(transaction, accounts);
    if (feeLamports > _highFeeLamports) {
      warnings.add(S.current.wc_warning_high_network_fee);
    }

    final onlyTitle = shownInstructions == 1 ? decodedTitle : null;
    return WCDecodedRequest(
      actionTitle: onlyTitle ?? S.current.wc_action_sign_transaction,
      rows: [
        ...instructionRows,
        ..._otherSignerRows(transaction, accounts, walletAddress),
        WCDecodedRow(
          label: S.current.wc_network_fee,
          value: "~ ${SystemProgramDecoder.formatSol(feeLamports)} SOL",
          kind: WCDecodedRowKind.amount,
        ),
      ],
      warnings: warnings.toList(),
    );
  }

  List<WCDecodedRow> _otherSignerRows(
    SolanaTransaction transaction,
    List<String> accounts,
    String walletAddress,
  ) => [
    for (final signer in accounts.take(transaction.message.header.numRequiredSignatures))
      if (signer != walletAddress)
        WCDecodedRow(
          label: S.current.wc_other_signers,
          value: signer,
          kind: WCDecodedRowKind.address,
        ),
  ];

  Future<SolDecodedInstruction?> _decodeInstruction(
    String programId,
    List<int> data,
    List<String?> accounts,
    String walletAddress,
    _RequestLookups lookups,
  ) async {
    try {
      if (programId == SolanaProgramIds.systemProgram) {
        return const SystemProgramDecoder().decode(data: data, accounts: accounts);
      }

      if (SolanaProgramIds.isTokenProgram(programId)) {
        return await SplTokenDecoder(
          lookups.resolver,
          lookups.fetcher,
        ).decode(data: data, accounts: accounts, wallet: walletAddress);
      }

      if (programId == SolanaProgramIds.associatedTokenProgram) {
        return await AtaDecoder(
          lookups.resolver,
        ).decode(data: data, accounts: accounts, wallet: walletAddress);
      }

      if (SolanaProgramIds.isMemoProgram(programId)) {
        return MemoDecoder().decode(data);
      }
    } catch (e, s) {
      printV("SolanaRequestDecoder: $programId instruction decode failed: $e\n$s");
    }
    return null;
  }

  BigInt _feeLamports(SolanaTransaction transaction, List<String> accounts) {
    var unitPrice = BigInt.zero;
    int? unitLimit;
    var defaultUnitLimit = 0;
    var signatures = transaction.message.header.numRequiredSignatures;
    for (final instruction in transaction.message.compiledInstructions) {
      final programId = instruction.programIdIndex < accounts.length
          ? accounts[instruction.programIdIndex]
          : null;
      final isBuiltin =
          programId == SolanaProgramIds.systemProgram ||
          programId == SolanaProgramIds.computeBudget;
      defaultUnitLimit += isBuiltin
          ? _builtinInstructionComputeUnits
          : _otherInstructionComputeUnits;

      final bytes = SolInstructionBytes(instruction.data);
      if (programId != null && SolanaProgramIds.isSignatureVerifier(programId)) {
        signatures += bytes.u8(0) ?? 0;
      }

      if (programId != SolanaProgramIds.computeBudget) {
        continue;
      }
      final tag = bytes.u8(0);
      if (tag == _setUnitLimitTag) {
        unitLimit = bytes.u32Le(1);
      }
      if (tag == _setUnitPriceTag) {
        unitPrice = bytes.u64Le(1) ?? unitPrice;
      }
    }

    final chargedUnits = min(unitLimit ?? defaultUnitLimit, _maxComputeUnits);
    final microLamports = unitPrice * BigInt.from(chargedUnits);
    return BigInt.from(signatures * _lamportsPerSignature) +
        (microLamports + BigInt.from(999999)) ~/ BigInt.from(1000000);
  }

  Future<WCDecodedRequest> decodeAllTransactions(
    Map<String, dynamic> params, {
    required String walletAddress,
  }) {
    final raw = const JsonEncoder.withIndent("  ").convert(params);

    return _withLookups((lookups) async {
      final transactions = transactionsFromParams(params);
      final rows = <WCDecodedRow>[];
      final warnings = <String>{};
      for (final (index, transaction) in transactions.indexed) {
        final decoded = await _decodeTransaction(
          transaction,
          walletAddress: walletAddress,
          lookups: lookups,
        );
        final label = S.current.wc_transaction_n((index + 1).toString());
        rows.add(WCDecodedRow(label: label, value: decoded.actionTitle));
        rows.addAll(decoded.rows);
        warnings.addAll(decoded.warnings);
      }

      return WCDecodedRequest(
        actionTitle: S.current.wc_action_sign_all_transactions,
        actionSubtitle: S.current.wc_transactions_count(transactions.length.toString()),
        rows: rows,
        warnings: warnings.toList(),
        rawFallback: raw,
      );
    });
  }

  List<SolanaTransaction> transactionsFromParams(Map<String, dynamic> params) {
    final entries = (params["transactions"] as List?)?.cast<String>() ?? const [];
    final parsed = [
      for (final entry in entries) transactionFromParams({"transaction": entry}),
    ];
    if (parsed.contains(null)) {
      throw const FormatException(
        "solana_signAllTransactions carries a transaction that does not parse",
      );
    }

    return parsed.nonNulls.toList();
  }

  SolanaTransaction? transactionFromParams(Map<String, dynamic> params) {
    try {
      if (params.containsKey("transaction")) {
        final transactionStr = params["transaction"] as String;
        if (transactionStr.length > _maxTransactionChars) {
          printV("SolanaRequestDecoder: transaction is longer than $_maxTransactionChars chars");
          return null;
        }

        final received = base64.decode(transactionStr);
        final transaction = SolanaTransaction.deserialize(received);
        final message = transaction.serializeMessage();
        final messageStart = 1 + received.first * 64;
        if (received.length != messageStart + message.length ||
            !BytesUtils.bytesEqual(received.sublist(messageStart), message)) {
          printV("SolanaRequestDecoder: transaction is not in the encoding the wallet signs");
          return null;
        }

        return transaction;
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
    final data = (json["data"] as List).map((byte) => byte as int).toList();
    final keys = (json["keys"] as List).map((key) {
      final meta = key as Map<String, dynamic>;
      return AccountMeta(
        publicKey: SolAddress(meta["pubkey"] as String),
        isWritable: meta["isWritable"] as bool,
        isSigner: meta["isSigner"] as bool,
      );
    }).toList();
    return TransactionInstruction.fromBytes(
      programId: SolAddress(programId),
      instructionBytes: data,
      keys: keys,
    );
  }
}

class _RequestLookups {
  _RequestLookups(AppStore? appStore, SolanaLookupBudget budget)
    : resolver = SplTokenResolver(appStore, budget),
      fetcher = SolanaAccountFetcher(appStore, budget);

  final SplTokenResolver resolver;
  final SolanaAccountFetcher fetcher;
}
