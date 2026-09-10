import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class CurrencyPickerSearchField extends StatelessWidget {
  const CurrencyPickerSearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border.all(color: colors.surfaceContainer, width: 1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(Icons.search, size: 20, color: colors.primary)),
            const SizedBox(width: 10),
            Expanded(
              // The hint names the field only while it is empty, so the label is
              // supplied once there is text to keep exactly one announcement.
              child: MergeSemantics(
                child: Semantics(
                  label: controller.text.isEmpty ? null : hintText,
                  child: TextFormField(
                    controller: controller,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hintText,
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              Semantics(
                button: true,
                label: S.of(context).clear,
                child: InkWell(
                  onTap: controller.clear,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: colors.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool currencyMatchesQuery(CryptoCurrency c, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  if (c.title.toLowerCase().contains(q)) return true;
  if (c.name.toLowerCase().contains(q)) return true;
  if (c.fullName?.toLowerCase().contains(q) ?? false) return true;
  if (c.tag?.toLowerCase().contains(q) ?? false) return true;
  if (chainNameForCurrency(c).toLowerCase().contains(q)) return true;
  return false;
}
