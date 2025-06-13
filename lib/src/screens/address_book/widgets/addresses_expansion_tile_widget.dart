import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef EditCallback = void Function(CryptoCurrency currency, String label);
typedef CopyCallback = void Function(String address);
typedef ManualByCurrencyMap = Map<CryptoCurrency, Map<String, String>>;

class ContactAddressesExpansionTile extends StatelessWidget {
  const ContactAddressesExpansionTile({
    super.key,
    required this.manualByCurrency,
    required this.fillColor,
    this.title,
    this.contentPadding,
    this.onEditPressed,
    this.onCopyPressed,
  });

  final ManualByCurrencyMap manualByCurrency;
  final Color fillColor;
  final Widget? title;
  final EdgeInsetsGeometry? contentPadding;
  final EditCallback? onEditPressed;
  final CopyCallback? onCopyPressed;

  Widget _circleIcon({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    ShapeBorder? shape,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return RawMaterialButton(
      onPressed: onPressed,
      fillColor: colorScheme.surfaceContainerHighest,
      elevation: 0,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: shape ?? const CircleBorder(),
      child: Icon(icon, size: 14, color: colorScheme.onSurface),
    );
  }

  Widget _addressRow(
    BuildContext c, {
    required CryptoCurrency currency,
    required String label,
    required String address,
  }) {
    return ListTile(
      title: Text(label, style: Theme.of(c).textTheme.bodyMedium),
      subtitle: AddressFormatter.buildSegmentedAddress(
        address: address,
        walletType: cryptoCurrencyToWalletType(currency),
        evenTextStyle: Theme.of(c).textTheme.labelSmall!,
        visibleChunks: 4,
        shouldTruncate: true,
      ),
      leading: ImageUtil.getImageFromPath(
        imagePath: currency.iconPath ?? '',
        height: 24,
        width: 24,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleIcon(
            context: c,
            icon: Icons.edit,
            onPressed: () => onEditPressed?.call(currency, label),
          ),
          const SizedBox(width: 8),
          _circleIcon(
            context: c,
            icon: Icons.copy_all_outlined,
            onPressed: () => onCopyPressed?.call(address),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      contentPadding: EdgeInsets.zero,
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
            dividerColor: Colors.transparent,
            listTileTheme: ListTileThemeData(
              contentPadding: EdgeInsets.zero,
              horizontalTitleGap: 4,
            ),
          splashFactory : NoSplash.splashFactory,
          splashColor   : Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor    : Colors.transparent,),
        child: Padding(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: ExpansionTile(
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tilePadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: title ?? const SizedBox(),
            children: [
              for (final curEntry in manualByCurrency.entries) ...[
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
      ),
    );
  }
}
