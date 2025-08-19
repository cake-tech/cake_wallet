import 'package:flutter/material.dart';

class TabViewWrapper extends StatefulWidget {
  const TabViewWrapper({
    super.key,
    required this.tabs,
    required this.views,
    this.tabBarPadding = const EdgeInsets.only(right: 24),
    this.labelStyle,
    this.unselectedLabelStyle,
    this.indicatorColor,
  }) : assert(tabs.length == views.length, 'Tabs and views must be of equal length.');

  final List<Tab> tabs;
  final List<Widget> views;
  final EdgeInsets tabBarPadding;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? indicatorColor;

  @override
  State<TabViewWrapper> createState() => _TabViewWrapperState();
}

class _TabViewWrapperState extends State<TabViewWrapper> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
        fontSize: 18,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            splashFactory: NoSplash.splashFactory,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: widget.labelStyle ?? textStyle,
            unselectedLabelStyle: widget.unselectedLabelStyle ??
                textStyle.copyWith(color: textStyle.color?.withAlpha(150)),
            labelColor: widget.labelStyle?.color ?? textStyle.color,
            indicatorColor: widget.indicatorColor,
            indicatorPadding: EdgeInsets.zero,
            labelPadding: widget.tabBarPadding,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            tabs: widget.tabs,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.views,
          ),
        ),
      ],
    );
  }
}
