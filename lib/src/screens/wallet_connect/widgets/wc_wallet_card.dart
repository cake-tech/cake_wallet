import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/clipboard_util.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WCWalletCard extends StatelessWidget {
  const WCWalletCard({
    super.key,
    required this.walletName,
    required this.address,
  });

  final String walletName;
  final String address;

  static String _truncate(String value) {
    if (value.length <= 14) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 7)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          WalletDetailEntry(label: S.of(context).wallet, value: walletName),
          Divider(height: 1, color: colors.outlineVariant),
          WalletDetailEntry(
            label: S.of(context).address,
            value: _truncate(address),
            onTap: address.isEmpty
                ? null
                : () async {
                    await ClipboardUtil.setSensitiveDataToClipboard(
                      ClipboardData(text: address),
                    );
                    if (!context.mounted) return;
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
          ),
        ],
      ),
    );
  }
}

class WalletDetailEntry extends StatelessWidget {
  const WalletDetailEntry({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
