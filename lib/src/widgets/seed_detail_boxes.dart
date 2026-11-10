import "dart:async";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class BlockHeightBox extends StatelessWidget {
  const BlockHeightBox({required this.height, this.isLoading = false, super.key});

  final String? height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => _SeedDetailBox(
        label: S.of(context).block_height,
        crossAxisAlignment: CrossAxisAlignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isLoading ? "Fetching..." : (height ?? "---"),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!isLoading && height != null)
              GestureDetector(
                onTap: () async {
                  await ClipboardUtil.setSensitiveDataToClipboard(ClipboardData(text: height!));
                  if (context.mounted) {
                    unawaited(
                      showBar<void>(
                        context,
                        S.of(context).copied_key_to_clipboard(S.of(context).block_height),
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      );
}

class PassphraseBox extends StatefulWidget {
  const PassphraseBox({required this.passphrase, super.key});

  final String passphrase;

  @override
  State<PassphraseBox> createState() => _PassphraseBoxState();
}

class _PassphraseBoxState extends State<PassphraseBox> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => _SeedDetailBox(
        label: S.of(context).passphrase_view_keys,
        crossAxisAlignment: CrossAxisAlignment.start,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _obscured ? "*****" : widget.passphrase,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _obscured = !_obscured),
              child: Icon(
                _obscured ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
}

class _SeedDetailBox extends StatelessWidget {
  const _SeedDetailBox({
    required this.label,
    required this.crossAxisAlignment,
    required this.child,
  });

  final String label;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(width: 6),
            Expanded(child: child),
          ],
        ),
      );
}
