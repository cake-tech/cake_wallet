import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';

class GroupedWalletExpansionTile extends StatelessWidget {
  GroupedWalletExpansionTile({
    required this.title,
    required this.isSelected,
    this.childWallets = const [],
    this.onTitleTapped,
    this.onChildItemTapped = _defaultVoidCallback,
    this.onExpansionChanged,
    this.leadingWidget,
    this.trailingWidget,
    this.childTrailingWidget,
    this.decoration,
    this.color,
    this.textColor,
    this.arrowColor,
    this.borderRadius,
    this.margin,
    this.tileKey,
    this.isCurrentlySelectedWallet = false,
    this.shouldShowCurrentWalletPointer = false,
  }) : super(key: tileKey);

  final Key? tileKey;
  final bool isSelected;
  final bool isCurrentlySelectedWallet;
  final bool shouldShowCurrentWalletPointer;

  final VoidCallback? onTitleTapped;
  final void Function(WalletListItem item) onChildItemTapped;
  final void Function(bool)? onExpansionChanged;

  final String title;
  final Widget? leadingWidget;
  final Widget? trailingWidget;
  final Widget Function(WalletListItem)? childTrailingWidget;

  final List<WalletListItem> childWallets;

  final Color? color;
  final Color? textColor;
  final Color? arrowColor;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final BorderRadius? borderRadius;

  static void _defaultVoidCallback(WalletListItem ITEM) {}

  @override
  Widget build(BuildContext context) {
    return GroupedWalletExpansionTileBody(
      color: color,
      isSelected: isSelected,
      textColor: textColor,
      arrowColor: arrowColor,
      onExpansionChanged: onExpansionChanged,
      shouldShowCurrentWalletPointer: shouldShowCurrentWalletPointer,
      childWallets: childWallets,
      tileKey: tileKey,
      isCurrentlySelectedWallet: isCurrentlySelectedWallet,
      leadingWidget: leadingWidget,
      trailingWidget: trailingWidget,
      onTitleTapped: onTitleTapped,
      title: title,
      childTrailingWidget: childTrailingWidget,
      onChildItemTapped: onChildItemTapped,
      context: context,
    );
  }
}

class GroupedWalletExpansionTileBody extends StatefulWidget {
  const GroupedWalletExpansionTileBody({
    super.key,
    required this.color,
    required this.isSelected,
    required this.textColor,
    required this.arrowColor,
    required this.onExpansionChanged,
    required this.shouldShowCurrentWalletPointer,
    required this.childWallets,
    required this.tileKey,
    required this.isCurrentlySelectedWallet,
    required this.leadingWidget,
    required this.trailingWidget,
    required this.onTitleTapped,
    required this.title,
    required this.childTrailingWidget,
    required this.onChildItemTapped,
    required this.context,
  });

  final Color? color;
  final bool isSelected;
  final Color? textColor;
  final Color? arrowColor;
  final void Function(bool p1)? onExpansionChanged;
  final bool shouldShowCurrentWalletPointer;
  final List<WalletListItem> childWallets;
  final Key? tileKey;
  final bool isCurrentlySelectedWallet;
  final Widget? leadingWidget;
  final Widget? trailingWidget;
  final VoidCallback? onTitleTapped;
  final String title;
  final Widget Function(WalletListItem p1)? childTrailingWidget;
  final void Function(WalletListItem item) onChildItemTapped;
  final BuildContext context;

  @override
  State<GroupedWalletExpansionTileBody> createState() =>
      _GroupedWalletExpansionTileBodyState();
}

class _GroupedWalletExpansionTileBodyState
    extends State<GroupedWalletExpansionTileBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.color ??
        (widget.isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainer);
    final effectiveTextColor = widget.textColor ??
        (widget.isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface);
    final effectiveArrowColor = widget.arrowColor ??
        (widget.isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedBackgroundColor: backgroundColor,
        backgroundColor: backgroundColor,
        onExpansionChanged: widget.onExpansionChanged,
        initiallyExpanded: widget.shouldShowCurrentWalletPointer
            ? widget.childWallets.any((element) => element.isCurrent)
            : false,
        key: widget.tileKey,
        tilePadding: EdgeInsets.symmetric(
            vertical: 1,
            horizontal: !widget.isCurrentlySelectedWallet ? 16 : 0),
        iconColor: effectiveArrowColor,
        collapsedIconColor: effectiveArrowColor,
        leading: widget.leadingWidget,
        trailing: widget.trailingWidget ??
            (widget.childWallets.isEmpty ? const SizedBox.shrink() : null),
        title: GestureDetector(
          onTap: widget.onTitleTapped,
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: effectiveTextColor,
                ),
            textAlign: TextAlign.left,
          ),
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                radius: const Radius.circular(8),
                thickness: 6,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: widget.childWallets.map((item) {
                      final currentColor = item.isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        key: ValueKey(item.name),
                        trailing: widget.childTrailingWidget?.call(item),
                        onTap: () => widget.onChildItemTapped(item),
                        leading: SizedBox(
                          width: 64,
                          child: Row(
                            children: [
                              if (item.isCurrent &&
                                  widget.shouldShowCurrentWalletPointer)
                                Container(
                                  height: 35,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    color: currentColor,
                                  ),
                                )
                              else
                                const SizedBox(width: 7),
                              const SizedBox(width: 24),
                              Image.asset(
                                walletTypeToCryptoCurrency(item.type).iconPath!,
                                width: 32,
                                height: 32,
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: effectiveTextColor,
                              ),
                        ),
                        subtitle: item.isReady ? null : Text(
                          'inactive wallet',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: effectiveTextColor.withAlpha(150),
                              ),
                      ));
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
