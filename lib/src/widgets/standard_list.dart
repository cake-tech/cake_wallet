import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/standart_list_card.dart';
import 'package:cake_wallet/src/widgets/standart_list_status_row.dart';
import 'package:flutter/material.dart';

class StandardListRow extends StatelessWidget {
  StandardListRow(
      {required this.title, required this.isSelected, this.onTap});

  final String title;
  final bool isSelected;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);

    return InkWell(
        onTap: () => onTap?.call(context),
        child: Container(
            color: _backgroundColor(context),
            height: 56,
            padding: EdgeInsets.only(left: 24, right: 24),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (leading != null) leading,
                  buildCenter(context, hasLeftOffset: leading != null),
                  if (trailing != null) trailing
                ])));
  }

  Widget? buildLeading(BuildContext context) => null;

  Widget buildCenter(BuildContext context, {required bool hasLeftOffset}) {
    // FIXME: find better way for keep text on left side.
    return Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      if (hasLeftOffset) SizedBox(width: 10),
      Expanded(
        child: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: titleColor(context),
            ),
        ),
      )
    ]));
  }

  Widget? buildTrailing(BuildContext context) => null;

  Color titleColor(BuildContext context) => isSelected
      ? Palette.blueCraiola
      : Theme.of(context).primaryTextTheme!.headline6!.color!;

  Color _backgroundColor(BuildContext context) {
    return Theme.of(context).backgroundColor;
  }
}

class SectionHeaderListRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(children: [
        StandardListSeparator(padding: EdgeInsets.only(left: 24)),
        Container(
            width: double.infinity,
            height: 40,
            color: Theme.of(context).backgroundColor),
        //StandardListSeparator(padding: EdgeInsets.only(left: 24))
      ]);
}

class StandardListSeparator extends StatelessWidget {

  StandardListSeparator({this.padding, this.height = 1});

  final EdgeInsets? padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        padding: padding,
        color: Theme.of(context).backgroundColor,
        child: Container(
            height: height,
            color: Theme.of(context).primaryTextTheme.headline6?.backgroundColor
            ));
  }
}

class StandardList extends StatelessWidget {
  StandardList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (_, __) =>
            StandardListSeparator(padding: EdgeInsets.only(left: 24)),
        itemCount: itemCount,
        itemBuilder: itemBuilder);

  }
}

class SectionStandardListItem {
  SectionStandardListItem({this.hasFullSeparator = false, required this.child});

  final bool hasFullSeparator;
  final Widget child;
}

class SectionStandardList extends StatelessWidget {
  SectionStandardList(
      {required this.itemCounter,
      required this.itemBuilder,
      required this.sectionCount,
      required BuildContext context,
      this.dividerPadding = const EdgeInsets.only(left: 24),
      this.themeColor,
      this.dividerThemeColor,
      this.sectionTitleBuilder,
      this.hasTopSeparator = false,})
      : totalRows = [] {
    totalRows.addAll(transform(
        hasTopSeparator,
        context,
        sectionCount,
        itemCounter,
        itemBuilder,
        sectionTitleBuilder,
        themeColor,
        dividerThemeColor));
  }

  final int sectionCount;
  final bool hasTopSeparator;
  final int Function(int sectionIndex) itemCounter;
  final Widget Function(BuildContext context, int sectionIndex, int itemIndex)
      itemBuilder;
  final Widget Function(BuildContext context, int sectionIndex)?
      sectionTitleBuilder;
  final List<Widget> totalRows;
  final Color? themeColor;
  final Color? dividerThemeColor;
  final EdgeInsets dividerPadding;

  List<Widget> transform(
      bool hasTopSeparator,
      BuildContext context,
      int sectionCount,
      int Function(int sectionIndex) itemCounter,
      Widget Function(BuildContext context, int sectionIndex, int itemIndex)
          itemBuilder,
      Widget Function(BuildContext context, int sectionIndex)?
          sectionTitleBuilder,
      Color? themeColor,
      Color? dividerThemeColor) {
    final items = <Widget>[];

    for (var sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
      if ((sectionIndex == 0) && (hasTopSeparator)) {
        items.add(StandardListSeparator(padding: EdgeInsets.only(left: 24)));
      }

      if (sectionTitleBuilder != null) {
        items.add(buildTitle(items, sectionIndex, context));
      }

      final itemCount = itemCounter(sectionIndex);

      items.addAll(buildSection(itemCount, items, sectionIndex, context));

      items.add(sectionIndex + 1 != sectionCount
          ? SectionHeaderListRow()
          : StandardListSeparator(padding: dividerPadding));
    }

    return items;
  }

  Widget buildTitle(
      List<Widget> items, int sectionIndex, BuildContext context) {
    if (sectionTitleBuilder == null) {
      throw Exception('Cannot to build title. sectionTitleBuilder is null');
    }

    return sectionTitleBuilder!.call(context, sectionIndex);
  }

  List<Widget> buildSection(int itemCount, List<Widget> items, int sectionIndex,
      BuildContext context) {
    final List<Widget> section = [];

    for (var itemIndex = 0; itemIndex < itemCount; itemIndex++) {
      final item = itemBuilder(context, sectionIndex, itemIndex);

      section.add(item);
    }
    return section;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (_, index) {
          final row = totalRows[index];

          if (row is StandardListSeparator || row is SectionHeaderListRow) {
            return Container();
          }

          if (row is StandartListStatusRow || row is TradeDatailsStandartListCard) {
            return Container();
          }

          final nextRow = totalRows[index + 1];

          // If current row is pre last and last row is separator.
          if (nextRow is StandardListSeparator ||
              nextRow is SectionHeaderListRow) {
            return Container();
          }

          return StandardListSeparator(padding: EdgeInsets.only(left: 24));
        },
        itemCount: totalRows.length,
        itemBuilder: (_, index) => totalRows[index]);
  }
}
