import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

/// The "Transaction sent" confirmation for a manual shield.
///
/// A dedicated sheet rather than the send flow's screen because its Done must
/// clear the dashboard flag that drives it -- otherwise the dashboard, which
/// re-shows this after the post-signing auth reset, would loop.
class ZcashShieldSentSheet extends StatelessWidget {
  const ZcashShieldSentSheet({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.only(top: 64),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const SizedBox(height: 12),
                Text(
                  S.of(context).transaction_sent_new,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(),
                CakeImageWidget(
                  width: 200,
                  height: 200,
                  imageUrl: "assets/new-ui/birthday_cake.svg",
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDone,
                    child: Text(S.of(context).done),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
