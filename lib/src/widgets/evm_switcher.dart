import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'evm_switcher_row.dart';

class EvmSwitcherDataItem {
  final String name;
  final String svgPath;

  const EvmSwitcherDataItem({
    required this.name,
    required this.svgPath,
  });

  static const ethereum = EvmSwitcherDataItem(
      name: 'Ethereum',
      svgPath: 'assets/images/evm_switcher_icons/ethereum.svg');

  static const polygon = EvmSwitcherDataItem(
      name: 'Polygon', svgPath: 'assets/images/evm_switcher_icons/polygon.svg');

  static const arbitrum = EvmSwitcherDataItem(
      name: 'Arbitrum',
      svgPath: 'assets/images/evm_switcher_icons/arbitrum.svg');

  static const base = EvmSwitcherDataItem(
      name: 'Base', svgPath: 'assets/images/evm_switcher_icons/base.svg');

  static const gnosis = EvmSwitcherDataItem(
      name: 'Gnosis', svgPath: 'assets/images/evm_switcher_icons/gnosis.svg');

  static const items = [
    ethereum,
    polygon,
    arbitrum,
    base,
    gnosis,
  ];
}

class EvmSwitcher extends StatefulWidget {
  const EvmSwitcher({super.key});

  static const editModeAnimDuration = Duration(milliseconds: 150);

  @override
  State<EvmSwitcher> createState() => _EvmSwitcherState();
}

class _EvmSwitcherState extends State<EvmSwitcher> {
  bool _editMode = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 25.0,
mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_editMode ? "Customize options":"Select Network", style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                width: 400,
                // height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EvmSwitcherAdditionalOption(
                        title: "Back",
                        svgPath: "assets/images/evm_switcher_arrow_left.svg",
                        animDuration: EvmSwitcher.editModeAnimDuration,
                        topSeparator: false,
                        bottomSeparator: true,
                        visible: _editMode,
                        onTap: () {
                          setState(() {
                            _editMode = false;
                          });
                        },iconOnRight: false),
                    ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return EvmSwitcherRow(
                            key: ValueKey(EvmSwitcherDataItem.items[index].name),
                            data: EvmSwitcherDataItem.items[index],
                            editMode: _editMode,
                            selected: index == _selectedIndex,
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            animDuration: EvmSwitcher.editModeAnimDuration,
                          );
                        },
                        separatorBuilder: (context, index) {
                          if (!(index == _selectedIndex ||
                                  index == _selectedIndex - 1) ||
                              _editMode)
                            return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                ));
                          else
                            return Container(height: 1);
                        },
                        itemCount: EvmSwitcherDataItem.items.length),
                    EvmSwitcherAdditionalOption(
                        title: "Customize options",
                        svgPath: "assets/images/evm_switcher_arrow_right.svg",
                        animDuration: EvmSwitcher.editModeAnimDuration,
                        topSeparator: true,
                        bottomSeparator: false,
                        visible: !_editMode,
                        onTap: () {
                          setState(() {
                            _editMode = true;
                          });
                        },
                        iconOnRight: true
                        )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

class EvmSwitcherAdditionalOption extends StatelessWidget {
  const EvmSwitcherAdditionalOption(
      {super.key,
      required this.title,
      required this.svgPath,
      required this.animDuration,
      required this.topSeparator,
      required this.bottomSeparator,
      required this.visible,
      required this.onTap, required this.iconOnRight});

  final String title;
  final String svgPath;
  final Duration animDuration;
  final bool topSeparator;
  final bool bottomSeparator;
  final bool visible;
  final VoidCallback onTap;
  final bool iconOnRight;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: Curves.easeOutCubic,
      duration: animDuration,
      child: Container(
        height: visible ? null : 0,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (topSeparator)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    )),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8.0,
                  children: [
                    if(!iconOnRight) SvgPicture.asset(svgPath, width: 16, height: 16),
                    Text(
                      title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    if(iconOnRight) SvgPicture.asset(svgPath, width: 16, height: 16),
                  ],
                ),
              ),
              if (bottomSeparator)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
