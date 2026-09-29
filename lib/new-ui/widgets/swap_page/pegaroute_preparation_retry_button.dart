import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_preparation_retry.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:flutter/material.dart';

/// Mounted only for a failed Pegaroute preparation/confirmation. The normal
/// send/approval swiper remains the sole UI broadcast action after preparation.
class PegaroutePreparationRetryButton extends StatefulWidget {
  const PegaroutePreparationRetryButton({
    super.key,
    required this.readAction,
    required this.onRetry,
  });

  final Future<PegaroutePreparationRetryAction?> Function() readAction;
  final Future<void> Function() onRetry;

  @override
  State<PegaroutePreparationRetryButton> createState() => _PegaroutePreparationRetryButtonState();
}

class _PegaroutePreparationRetryButtonState extends State<PegaroutePreparationRetryButton> {
  late Future<PegaroutePreparationRetryAction?> _action;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _action = _readAction();
  }

  Future<PegaroutePreparationRetryAction?> _readAction() async {
    try {
      return await widget.readAction();
    } catch (_) {
      // Missing/unavailable/corrupt persistence is not proof of no submission.
      return null;
    }
  }

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Another screen, a status refresh or expiry may have invalidated the
      // displayed action. Re-read before touching wallet preparation.
      final action = await _readAction();
      if (!mounted) return;
      if (action == null) {
        setState(() {
          _action = Future.value(null);
        });
        return;
      }
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PegaroutePreparationRetryAction?>(
        future: _action,
        builder: (context, snapshot) {
          final action = snapshot.data;
          if (action == null) return const SizedBox.shrink();
          final label = switch (action) {
            PegaroutePreparationRetryAction.retryPreparation =>
              S.of(context).pegaroute_retry_preparation,
            PegaroutePreparationRetryAction.checkApproval => S.of(context).pegaroute_check_approval,
            PegaroutePreparationRetryAction.continuePreparation => S.of(context).continue_text,
          };
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: NewPrimaryButton(
              onPressed: _retry,
              text: label,
              disabled: _busy,
              isLoading: _busy,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        },
      );
}
