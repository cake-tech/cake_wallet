import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/view_model/dashboard/receive_option_view_model.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ReceiveAddressTypeSelector extends StatefulWidget {
  const ReceiveAddressTypeSelector({super.key, required this.receiveOptionViewModel});

  final ReceiveOptionViewModel receiveOptionViewModel;

  static const otherOptionsExpandDuration = Duration(milliseconds: 300);

  @override
  State<ReceiveAddressTypeSelector> createState() => _ReceiveAddressTypeSelectorState();
}

class _ReceiveAddressTypeSelectorState extends State<ReceiveAddressTypeSelector> {
  late bool _otherOptionsExpanded;

  @override
  void initState() {
    super.initState();
    _otherOptionsExpanded = !widget.receiveOptionViewModel.selectedReceiveOption.isCommon;
  }


  @override
  Widget build(BuildContext context) {
    final commonOptions =
        widget.receiveOptionViewModel.options.where((element) => element.isCommon).toList();
    final otherOptions =
        widget.receiveOptionViewModel.options.where((element) => !element.isCommon).toList();

    return SafeArea(
      child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.zero),
          ),
          child: ListView(
            controller: ModalScrollController.of(context),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              ModalTopBar(
                  title: "Address Type",
                  leadingIcon: Icon(Icons.close),
                  onLeadingPressed: Navigator.of(context).pop,
                  onTrailingPressed: () {}),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: commonOptions.length,
                    itemBuilder: (context, index) {
                      final opt = commonOptions[index];

                      return ReceiveAddressTypeRow(
                        option: opt,
                        roundedTop: index == 0,
                        roundedBottom: index == commonOptions.length - 1,
                        selected: widget.receiveOptionViewModel.selectedReceiveOption == opt,
                        onItemTap: () {
                          widget.receiveOptionViewModel.selectReceiveOption(opt);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36.0),
                        child: HorizontalSectionDivider(),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _otherOptionsExpanded = !_otherOptionsExpanded;
                          });
                        },
                        child: Container(
                          height: 64.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "More options",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.primary),
                                ),
                                AnimatedRotation(
                                    duration: ReceiveAddressTypeSelector.otherOptionsExpandDuration,
                                    turns: _otherOptionsExpanded? 0.0:0.5,
                                    curve: Curves.easeOut,
                                    child: SvgPicture.asset("assets/new-ui/dropdown_arrow.svg"))
                              ],
                            ),
                          ),
                        ),
                      ),
                      if(_otherOptionsExpanded) Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 27.0),
                        child: HorizontalSectionDivider(),
                      ),
                      AnimatedSize(
                        duration: ReceiveAddressTypeSelector.otherOptionsExpandDuration,
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: _otherOptionsExpanded ? null : 0,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: otherOptions.length,
                            itemBuilder: (context, index) {
                              final opt = otherOptions[index];

                              return ReceiveAddressTypeRow(
                                option: opt,
                                roundedTop: index == 0,
                                roundedBottom: index == otherOptions.length - 1,
                                selected: widget.receiveOptionViewModel.selectedReceiveOption == opt,
                                onItemTap: () {
                                  widget.receiveOptionViewModel.selectReceiveOption(opt);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 27.0),
                                child: HorizontalSectionDivider(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          )),
    );
  }
}

class ReceiveAddressTypeRow extends StatelessWidget {
  const ReceiveAddressTypeRow(
      {super.key,
      required this.option,
      required this.roundedTop,
      required this.roundedBottom,
      required this.selected,
      required this.onItemTap});

  final ReceivePageOption option;
  final bool roundedTop;
  final bool roundedBottom;
  final bool selected;
  final VoidCallback onItemTap;

  static const iconSize = 24.0;
  static const rowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onItemTap,
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
            color:
                selected ? Theme.of(context).colorScheme.surfaceContainerHigh : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: roundedTop ? Radius.circular(20) : Radius.zero,
              bottom: roundedBottom ? Radius.circular(20) : Radius.zero,
            )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  if (option.iconPath != null)
                    SvgPicture.asset(option.iconPath!, width: iconSize, height: iconSize)
                  else
                    Container(width: iconSize, height: iconSize),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
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
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        if (option.description != null)
                          Text(
                            option.description!,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          )
                      ],
                    ),
                  )
                ],
              ),
              RoundedCheckbox(value: selected)
            ],
          ),
        ),
      ),
    );
  }
}
