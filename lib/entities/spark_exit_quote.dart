/// A Spark leaf an exit would recover, with its value formatted for display.
class SparkExitLeaf {
  const SparkExitLeaf({required this.id, required this.amount, required this.isCooperative});

  final String id;
  final String amount;

  /// The operators already moved it on-chain, so it comes back with their signature and
  /// pays its own fee rather than taking funding.
  final bool isCooperative;
}

/// A leaf the exit leaves out, and why, in words.
class SparkExitSkippedLeaf {
  const SparkExitSkippedLeaf({required this.id, required this.amount, required this.reason});

  final String id;
  final String amount;
  final String reason;
}

/// What a Spark exit at one fee rate would recover and cost, or why it can't be done.
/// Amounts are already formatted for display.
class SparkExitQuote {
  const SparkExitQuote({
    required this.isRebuild,
    required this.recoverableAmount,
    required this.feeAmount,
    required this.failureMessage,
    required this.leaves,
    required this.skipped,
  });

  const SparkExitQuote.failed({required String this.failureMessage})
      : isRebuild = false,
        recoverableAmount = null,
        feeAmount = null,
        leaves = const [],
        skipped = const [];

  /// An exit is already under way, and this quotes building it again at a new fee rate.
  final bool isRebuild;

  final String? recoverableAmount;
  final String? feeAmount;
  final String? failureMessage;
  final List<SparkExitLeaf> leaves;
  final List<SparkExitSkippedLeaf> skipped;

  bool get isWorthExiting => failureMessage == null;
}
