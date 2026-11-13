import "dart:async";

import "package:cake_wallet/entities/spark_exit_quote.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/spark_exit/spark_exit_leaf_picker.dart";
import "package:cake_wallet/new-ui/widgets/spark_exit/spark_exit_merging_leaves.dart";
import "package:cake_wallet/new-ui/widgets/spark_exit/spark_exit_quote_summary.dart";
import "package:cake_wallet/new-ui/widgets/spark_exit/spark_fee_rate_section.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

/// Intro to the Spark exit that also picks the fee rate it is built at and which leaves it
/// recovers. While an exit is under way it raises that exit's fee instead. Pops with the
/// chosen rate in sat/vB and the chosen leaves (null for all), or nothing when the user
/// backs out.
class SparkUnilateralExitSheet extends StatefulWidget {
  const SparkUnilateralExitSheet({
    required this.bitcoinFeeRatePriorities,
    required this.initialFeeRate,
    required this.maxFeeRate,
    required this.mergeLeaves,
    required this.quoteExit,
    super.key,
  });

  /// The fee rate priorities to offer as chips, in the order the settings picker shows them.
  final List<({TransactionPriority priority, int feeRate})> bitcoinFeeRatePriorities;
  final int initialFeeRate;
  final int maxFeeRate;

  /// Merges the Spark balance into fewer, larger leaves before the first quote, so more of
  /// it is worth exiting. Never fails: without the merge the quote uses the current leaves.
  final Future<void> Function() mergeLeaves;

  /// Quotes the exit at a fee rate, of the given leaves or every leaf worth it when null, so
  /// the sheet can show whether it is worth it.
  final Future<SparkExitQuote> Function(int feeRate, List<String>? leafIds) quoteExit;

  @override
  State<SparkUnilateralExitSheet> createState() => _SparkUnilateralExitSheetState();
}

class _SparkUnilateralExitSheetState extends State<SparkUnilateralExitSheet> {
  static final _withdrawalsDocsUri = Uri.https("docs.spark.money", "/learn/withdrawals");
  static const _quoteDebounce = Duration(milliseconds: 400);

  late final TextEditingController _feeRateController;
  Timer? _quoteTimer;

  /// The latest quote; null while one is pending.
  SparkExitQuote? _quote;

  /// Counts quote requests, so only the latest one's answer is shown.
  int _quoteRequest = 0;

  /// Every leaf worth exiting, from the latest quote of all of them, to choose from.
  List<SparkExitLeaf> _availableLeaves = const [];

  /// The leaves the user chose; null when they keep all of them.
  Set<String>? _selectedLeafIds;

  /// Leaves are being merged; quotes wait for it, since the merge changes them.
  bool _isMerging = true;

  @override
  void initState() {
    super.initState();
    _feeRateController = TextEditingController(text: widget.initialFeeRate.toString());
    _mergeThenQuote();
  }

  Future<void> _mergeThenQuote() async {
    await widget.mergeLeaves();

    if (!mounted) {
      return;
    }

    setState(() => _isMerging = false);

    final rate = _feeRate;
    if (rate != null) {
      await _requestQuote(rate);
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _feeRateController.dispose();
    super.dispose();
  }

  void _onFeeRateChanged() {
    _quoteTimer?.cancel();
    _quoteRequest++;
    setState(() => _quote = null);

    final rate = _feeRate;
    if (rate == null || _isMerging || _selectedLeafIds?.isEmpty == true) {
      return;
    }

    _quoteTimer = Timer(_quoteDebounce, () => _requestQuote(rate));
  }

  Future<void> _requestQuote(int rate) async {
    final request = ++_quoteRequest;
    final selection = _selectedLeafIds;
    final quote = await widget.quoteExit(rate, selection?.toList());

    // The rate or the chosen leaves changed while this one was being quoted.
    if (!mounted || request != _quoteRequest) {
      return;
    }

    setState(() {
      _quote = quote;

      if (selection == null && !quote.isRebuild) {
        _availableLeaves = quote.leaves;
      }
    });
  }

  void _toggleLeaf(String leafId) {
    final selection = _selectedLeafIds ?? _availableLeaves.map((leaf) => leaf.id).toSet();
    final toggled =
        selection.contains(leafId) ? ({...selection}..remove(leafId)) : {...selection, leafId};

    // Choosing every leaf again goes back to letting the SDK pick all that are worth it.
    _selectedLeafIds = toggled.length == _availableLeaves.length ? null : toggled;
    _onFeeRateChanged();
  }

  /// The typed fee rate, or null when it cannot be used.
  int? get _feeRate {
    final rate = int.tryParse(_feeRateController.text);
    if (rate == null || rate < 1 || rate > widget.maxFeeRate) {
      return null;
    }

    return rate;
  }

  void _selectFeeRate(int rate) {
    _feeRateController.text = rate.toString();
    _onFeeRateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final feeRate = _feeRate;
    final quote = _quote;
    final isRebuild = quote?.isRebuild == true;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTopBar(
                title: isRebuild
                    ? S.of(context).spark_exit_rebuild_title
                    : S.of(context).spark_unilateral_exit_title,
                trailingIcon: const Icon(Icons.close),
                trailingSemanticLabel: S.of(context).close,
                onTrailingPressed: Navigator.of(context).pop,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  spacing: 16,
                  children: [
                    Text(
                      isRebuild
                          ? S.of(context).spark_exit_rebuild_description
                          : S.of(context).spark_unilateral_exit_description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      S.of(context).spark_unilateral_exit_confirmation,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SparkFeeRateSection(
                      controller: _feeRateController,
                      feeRate: feeRate,
                      bitcoinFeeRatePriorities: widget.bitcoinFeeRatePriorities,
                      maxFeeRate: widget.maxFeeRate,
                      onFeeRateSelected: _selectFeeRate,
                      onFeeRateChanged: (_) => _onFeeRateChanged(),
                    ),
                    if (_isMerging)
                      const SparkExitMergingLeaves()
                    else if (feeRate != null) ...[
                      if (!isRebuild && quote != null)
                        SparkExitLeafPicker(
                          leaves: _availableLeaves,
                          selectedLeafIds: _selectedLeafIds,
                          skipped: quote.skipped,
                          onLeafToggled: _toggleLeaf,
                        ),
                      if (_selectedLeafIds?.isEmpty != true) SparkExitQuoteSummary(quote: quote),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 12,
                  children: [
                    NewPrimaryButton(
                      key: const ValueKey("spark_unilateral_exit_learn_more_button_key"),
                      onPressed: _launchWithdrawalsDocs,
                      text: S.of(context).learn_more,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      textColor: Theme.of(context).colorScheme.primary,
                    ),
                    NewPrimaryButton(
                      key: const ValueKey("spark_unilateral_exit_continue_button_key"),
                      onPressed: () => Navigator.of(context)
                          .pop((feeRate: feeRate!, leafIds: _selectedLeafIds?.toList())),
                      disabled: feeRate == null ||
                          _selectedLeafIds?.isEmpty == true ||
                          quote?.isWorthExiting != true,
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWithdrawalsDocs() async {
    try {
      await launchUrl(_withdrawalsDocsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      printV("Failed to open Spark withdrawals docs: $e");
    }
  }
}
