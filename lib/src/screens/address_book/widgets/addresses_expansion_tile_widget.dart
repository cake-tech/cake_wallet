import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

typedef EditCallback = void Function(CryptoCurrency currency, String label);
typedef OnStringAction = void Function(String address);
typedef AddressByCurrencyMap = Map<CryptoCurrency, Map<String, String>>;

class ContactAddressesExpansionTile extends StatelessWidget {
  const ContactAddressesExpansionTile({
    super.key,
    required this.addressByCurrency,
    required this.fillColor,
    this.title,
    this.contentPadding,
    this.tilePadding,
    this.onEditPressed,
    this.onCopyPressed,
    this.onAddressPressed,
    this.initiallyExpanded = false,
    this.shouldTruncateContent = true,
  });

  final AddressByCurrencyMap addressByCurrency;
  final Color fillColor;
  final Widget? title;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? tilePadding;
  final EditCallback? onEditPressed;
  final OnStringAction? onCopyPressed;
  final OnStringAction? onAddressPressed;
  final bool initiallyExpanded;
  final bool shouldTruncateContent;

  Widget _addressRow(BuildContext context,
      {required CryptoCurrency currency, required String label, required String address}) {
    return ListTile(
      title: Text(label, style: Theme
          .of(context)
          .textTheme
          .bodyMedium),
      subtitle: AddressFormatter.buildSegmentedAddress(
          address: address,
          walletType: cryptoCurrencyToWalletType(currency),
          evenTextStyle: Theme
              .of(context)
              .textTheme
              .labelSmall!,
          visibleChunks: 4,
          shouldTruncate: shouldTruncateContent),
      leading:
      ImageUtil.getImageFromPath(imagePath: currency.iconPath ?? '', height: 24, width: 24),
      trailing: onEditPressed != null || onCopyPressed != null ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEditPressed != null)
          RoundedIconButton(
            icon: Icons.edit,
            onPressed: () => onEditPressed?.call(currency, label)
          ),
          const SizedBox(width: 8),
          if (onCopyPressed != null)
          RoundedIconButton(
            icon: Icons.copy_all_outlined,
            onPressed: () => onCopyPressed?.call(address),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ) : null,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      contentPadding: contentPadding ??
          const EdgeInsets.only(left: 24, right: 16),
      onTap: () => onAddressPressed?.call(address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: fillColor,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          dividerColor: Colors.transparent,
          listTileTheme: const ListTileThemeData(
            dense: true,
            minLeadingWidth: 0,
            horizontalTitleGap: 8,
            minVerticalPadding: 0,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity(
              horizontal: -4,
              vertical: -4,
            ),
          ),
          expansionTileTheme: const ExpansionTileThemeData(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
          ),
        ),
        child: ExpansionTile(
          iconColor: Theme
              .of(context)
              .colorScheme
              .onSurfaceVariant,
          tilePadding: tilePadding ?? const EdgeInsets.only(left: 8, right: 16),
          initiallyExpanded: initiallyExpanded,
          dense: true,
          visualDensity: VisualDensity.compact,
          title: title ?? const SizedBox(),
          children: [
            for (final curEntry in addressByCurrency.entries) ...[
              for (final labelEntry in curEntry.value.entries)
                _addressRow(
                  context,
                  currency: curEntry.key,
                  label: labelEntry.key,
                  address: labelEntry.value,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
