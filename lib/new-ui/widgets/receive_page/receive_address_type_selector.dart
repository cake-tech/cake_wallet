import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/rounded_checkbox.dart";
import "package:cake_wallet/src/widgets/section_divider.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ReceiveAddressTypeSelector extends StatefulWidget {
  const ReceiveAddressTypeSelector({
    required this.options,
    required this.selected,
    required this.walletType,
    super.key,
  });

  final List<ReceivePageOption> options;
  final ReceivePageOption selected;
  final WalletType walletType;

  static const otherOptionsExpandDuration = Duration(milliseconds: 300);
  static const otherOptionsThreshold = 3;

  @override
  State<ReceiveAddressTypeSelector> createState() => _ReceiveAddressTypeSelectorState();
}

class _ReceiveAddressTypeSelectorState extends State<ReceiveAddressTypeSelector> {
  late bool _otherOptionsExpanded;

  @override
  void initState() {
    super.initState();
    _otherOptionsExpanded = !widget.selected.isCommon;
  }

  @override
  Widget build(BuildContext context) {
    final commonOptions = widget.options
        .where(
          (element) =>
              element.isCommon ||
              widget.options.length <= ReceiveAddressTypeSelector.otherOptionsThreshold,
        )
        .toList();
    commonOptions.sort((a, b) {
      final preferred = widget.selected.value.contains("Lightning") ? "Lightning" : "Standard";
      if (a.value.contains(preferred)) {
        return -1;
      }
      if (b.value.contains(preferred)) {
        return 1;
      }
      return a.value.compareTo(b.value);
    });
    final otherOptions = widget.options
        .where(
          (element) =>
              !element.isCommon &&
              widget.options.length > ReceiveAddressTypeSelector.otherOptionsThreshold,
        )
        .toList();

    return SafeArea(
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ModalScrollController.of(context),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            ModalTopBar(
              title: S.of(context).address_type,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: commonOptions.length,
                  itemBuilder: (context, index) {
                    final opt = commonOptions[index];
                    return ReceiveAddressTypeRow(
                      option: opt,
                      walletType: widget.walletType,
                      roundedTop: index == 0,
                      roundedBottom: index == commonOptions.length - 1,
                      selected: widget.selected == opt,
                      onItemTap: () => Navigator.of(context).pop(opt),
                    );
                  },
                  separatorBuilder: (context, index) {
                    if ((widget.selected == commonOptions[index]) ||
                        (index != commonOptions.length - 1 &&
                            widget.selected == commonOptions[index + 1])) {
                      return Container();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(left: 44, right: 36),
                      child: HorizontalSectionDivider(),
                    );
                  },
                ),
              ),
            ),
            if (otherOptions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(20),
                          bottom: _otherOptionsExpanded ? Radius.zero : const Radius.circular(20),
                        ),
                        child: MergeSemantics(
                          child: Semantics(
                            button: true,
                            expanded: _otherOptionsExpanded,
                            child: InkWell(
                              highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(20),
                                bottom: !_otherOptionsExpanded
                                    ? Radius.zero
                                    : const Radius.circular(20),
                              ),
                              onTap: () => setState(
                                () => _otherOptionsExpanded = !_otherOptionsExpanded,
                              ),
                              child: SizedBox(
                                height: 64,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        S.of(context).more_options,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      ExcludeSemantics(
                                        child: AnimatedRotation(
                                          duration:
                                              ReceiveAddressTypeSelector.otherOptionsExpandDuration,
                                          turns: _otherOptionsExpanded ? 0.0 : 0.5,
                                          curve: Curves.easeOut,
                                          child: const CakeImageWidget(
                                            imageUrl: "assets/new-ui/dropdown_arrow.svg",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_otherOptionsExpanded)
                        const Padding(
                          padding: EdgeInsets.only(left: 44, right: 36),
                          child: HorizontalSectionDivider(),
                        ),
                      AnimatedSize(
                        duration: ReceiveAddressTypeSelector.otherOptionsExpandDuration,
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        // Collapsed to zero height: keep the options out of
                        // the semantics tree so they cannot be focused.
                        child: ExcludeSemantics(
                          excluding: !_otherOptionsExpanded,
                          child: SizedBox(
                            height: _otherOptionsExpanded ? null : 0,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: otherOptions.length,
                              itemBuilder: (context, index) {
                                final opt = otherOptions[index];
                                return ReceiveAddressTypeRow(
                                  option: opt,
                                  walletType: widget.walletType,
                                  roundedTop: false,
                                  roundedBottom: index == otherOptions.length - 1,
                                  selected: widget.selected == opt,
                                  onItemTap: () => Navigator.of(context).pop(opt),
                                );
                              },
                              separatorBuilder: (context, index) {
                                if ((widget.selected == otherOptions[index]) ||
                                    (index != otherOptions.length - 1 &&
                                        widget.selected == otherOptions[index + 1])) {
                                  return Container();
                                }
                                return const Padding(
                                  padding: EdgeInsets.only(left: 44, right: 36),
                                  child: HorizontalSectionDivider(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class ReceiveAddressTypeRow extends StatelessWidget {
  const ReceiveAddressTypeRow({
    required this.option,
    required this.walletType,
    required this.roundedTop,
    required this.roundedBottom,
    required this.selected,
    required this.onItemTap,
    super.key,
  });

  final ReceivePageOption option;
  final WalletType walletType;
  final bool roundedTop;
  final bool roundedBottom;
  final bool selected;
  final VoidCallback onItemTap;

  static const iconSize = 24.0;
  static const rowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    var iconPath = option.iconPath;
    if (iconPath != null &&
        walletType == WalletType.litecoin &&
        option.value.contains("Standard")) {
      iconPath = "assets/new-ui/address-type-picker-icons/litecoin.svg";
    }
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.vertical(
        top: roundedTop ? const Radius.circular(20) : Radius.zero,
        bottom: roundedBottom ? const Radius.circular(20) : Radius.zero,
      ),
      child: MergeSemantics(
        child: Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            onTap: onItemTap,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  top: roundedTop ? const Radius.circular(20) : Radius.zero,
                  bottom: roundedBottom ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (iconPath != null)
                          ExcludeSemantics(
                            child: CakeImageWidget(
                              imageUrl: iconPath,
                              width: iconSize,
                              height: iconSize,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: iconSize, height: iconSize),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (option.description != null)
                                Text(
                                  option.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ExcludeSemantics(child: RoundedCheckbox(value: selected)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
