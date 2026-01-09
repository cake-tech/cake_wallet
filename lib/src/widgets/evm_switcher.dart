import 'package:cake_wallet/evm/evm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'evm_switcher_row.dart';

class EvmSwitcherDataItem {
  final String name;
  final String svgPath;
  final int chainId;

  const EvmSwitcherDataItem({
    required this.name,
    required this.svgPath,
    required this.chainId,
  });

  static const ethereum = EvmSwitcherDataItem(
    name: 'Ethereum',
    svgPath: 'assets/images/evm_switcher_icons/ethereum.svg',
    chainId: 1,
  );

  static const polygon = EvmSwitcherDataItem(
    name: 'Polygon',
    svgPath: 'assets/images/evm_switcher_icons/polygon.svg',
    chainId: 137,
  );

  static const arbitrum = EvmSwitcherDataItem(
    name: 'Arbitrum',
    svgPath: 'assets/images/evm_switcher_icons/arbitrum.svg',
    chainId: 42161,
  );

  static const base = EvmSwitcherDataItem(
    name: 'Base',
    svgPath: 'assets/images/evm_switcher_icons/base.svg',
    chainId: 8453,
  );

  static const items = [
    ethereum,
    polygon,
    arbitrum,
    base,
  ];
}

String _getSvgPathForChain(String chainName) {
  final name = chainName.toLowerCase();
  if (name.contains('ethereum')) {
    return 'assets/images/evm_switcher_icons/ethereum.svg';
  } else if (name.contains('polygon')) {
    return 'assets/images/evm_switcher_icons/polygon.svg';
  } else if (name.contains('arbitrum')) {
    return 'assets/images/evm_switcher_icons/arbitrum.svg';
  } else if (name.contains('base')) {
    return 'assets/images/evm_switcher_icons/base.svg';
  }
  // Default to ethereum if unknown
  return 'assets/images/evm_switcher_icons/ethereum.svg';
}

class EvmSwitcher extends StatefulWidget {
  const EvmSwitcher({
    super.key,
    required this.chains,
    required this.currentChain,
    required this.onChainSelected,
    required this.hiddenChainIds,
    required this.onHiddenChanged,
  });

  final List<ChainInfo> chains;
  final ChainInfo? currentChain;
  final Future<void> Function(int chainId) onChainSelected;
  final Set<int> hiddenChainIds;
  final void Function(Set<int> hiddenChainIds) onHiddenChanged;

  static const editModeAnimDuration = Duration(milliseconds: 200);

  @override
  State<EvmSwitcher> createState() => _EvmSwitcherState();
}

class _EvmSwitcherState extends State<EvmSwitcher> {
  bool _editMode = false;
  var optionsEnabled = <bool>[];

  @override
  void initState() {
    super.initState();
    _syncOptionsEnabled();
  }

  @override
  void didUpdateWidget(covariant EvmSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chains != widget.chains ||
        !_hiddenSetsEqual(oldWidget.hiddenChainIds, widget.hiddenChainIds)) {
      _syncOptionsEnabled();
    }
  }

  void _syncOptionsEnabled() {
    optionsEnabled = widget.chains
        .map((chain) => !widget.hiddenChainIds.contains(chain.chainId))
        .toList(growable: false);
  }

  bool _hiddenSetsEqual(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  int get _selectedIndex {
    if (widget.currentChain == null) return -1;
    return widget.chains.indexWhere(
      (chain) => chain.chainId == widget.currentChain!.chainId,
    );
  }

  bool shouldBuildSeparator(int index) {
    final nextEnabled = optionsEnabled.indexWhere(
      (e) => e,
      index + 1,
    );

    return index != _selectedIndex &&
        optionsEnabled[index] &&
        nextEnabled != _selectedIndex &&
        nextEnabled != -1;
  }

  Set<int> _currentHiddenChainIds() {
    final hidden = <int>{};
    for (var i = 0; i < widget.chains.length; i++) {
      if (i < optionsEnabled.length && !optionsEnabled[i]) {
        hidden.add(widget.chains[i].chainId);
      }
    }
    return hidden;
  }

  @override
  Widget build(BuildContext context) {
    final double popupWidth = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: Column(
        spacing: 25.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _editMode ? "Customize options" : "Select Network",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: AnimatedContainer(
                  duration: EvmSwitcher.editModeAnimDuration,
                  width: popupWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedSize(
                        curve: Curves.easeOutCubic,
                        duration: EvmSwitcher.editModeAnimDuration,
                        child: Container(
                          width: _editMode ? 0 : popupWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    if (optionsEnabled[index]) {
                                      final chain = widget.chains[index];
                                      final data = EvmSwitcherDataItem(
                                        name: chain.name,
                                        svgPath: _getSvgPathForChain(chain.name),
                                        chainId: chain.chainId,
                                      );
                                      return EvmSwitcherRow(
                                        key: ValueKey(chain.chainId),
                                        data: data,
                                        editMode: false,
                                        selected: index == _selectedIndex,
                                        onTap: () {
                                          widget.onChainSelected(chain.chainId);
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        editSwitchValue: true,
                                        animDuration: EvmSwitcher.editModeAnimDuration,
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                  separatorBuilder: (context, index) {
                                    if (shouldBuildSeparator(index))
                                      return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 18),
                                          child: Container(
                                            height: 1,
                                            width: double.infinity,
                                            color:
                                                Theme.of(context).colorScheme.surfaceContainerHigh,
                                          ));
                                    else
                                      return Container(height: 1);
                                  },
                                  itemCount: widget.chains.length),
                              EvmSwitcherAdditionalOption(
                                  title: "Customize options",
                                  svgPath: "assets/images/evm_switcher_arrow_right.svg",
                                  animDuration: EvmSwitcher.editModeAnimDuration,
                                  topSeparator: true,
                                  bottomSeparator: false,
                                  visible: true,
                                  onTap: () {
                                    setState(() {
                                      _editMode = true;
                                    });
                                  },
                                  iconOnRight: true)
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        curve: Curves.easeOutCubic,
                        duration: EvmSwitcher.editModeAnimDuration,
                        child: Container(
                          width: _editMode ? popupWidth : 0,
                          height: _editMode ? null : 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EvmSwitcherAdditionalOption(
                                  title: "Back",
                                  svgPath: "assets/images/evm_switcher_arrow_left.svg",
                                  animDuration: EvmSwitcher.editModeAnimDuration,
                                  topSeparator: false,
                                  bottomSeparator: true,
                                  visible: true,
                                  onTap: () {
                                    setState(() {
                                      _editMode = false;
                                    });
                                  },
                                  iconOnRight: false),
                              ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final chain = widget.chains[index];
                                    final data = EvmSwitcherDataItem(
                                      name: chain.name,
                                      svgPath: _getSvgPathForChain(chain.name),
                                      chainId: chain.chainId,
                                    );
                                    return EvmSwitcherRow(
                                      key: ValueKey(chain.chainId),
                                      data: data,
                                      editMode: _editMode,
                                      selected: index == _selectedIndex,
                                      onTap: () {
                                        setState(() {
                                          optionsEnabled[index] = !optionsEnabled[index];
                                        });
                                        widget.onHiddenChanged(
                                          _currentHiddenChainIds(),
                                        );
                                      },
                                      editSwitchValue: optionsEnabled[index],
                                      animDuration: EvmSwitcher.editModeAnimDuration,
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        child: Container(
                                          height: 1,
                                          width: double.infinity,
                                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                        ));
                                  },
                                  itemCount: widget.chains.length),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
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
      required this.onTap,
      required this.iconOnRight});

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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
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
                  if (!iconOnRight) SvgPicture.asset(svgPath, width: 16, height: 16),
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  if (iconOnRight) SvgPicture.asset(svgPath, width: 16, height: 16),
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
    );
  }
}
