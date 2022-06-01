import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';

class CollapsibleSectionList extends SectionStandardList {
  CollapsibleSectionList(
      {bool hasTopSeparator,
        BuildContext context,
        int sectionCount,
        int Function(int sectionIndex) itemCounter,
        Widget Function(BuildContext context, int sectionIndex, int itemIndex)
        itemBuilder,
        Widget Function(BuildContext context, int sectionIndex)
        sectionTitleBuilder,
        Color themeColor,
        Color dividerThemeColor})
      : super(
      hasTopSeparator: hasTopSeparator,
      sectionCount: sectionCount,
      itemCounter: itemCounter,
      itemBuilder: itemBuilder,
      sectionTitleBuilder: sectionTitleBuilder,
      themeColor: themeColor,
      dividerThemeColor: dividerThemeColor);

  @override
  List<Widget> transform(
      bool hasTopSeparator,
      BuildContext context,
      int sectionCount,
      int Function(int sectionIndex) itemCounter,
      Widget Function(BuildContext context, int sectionIndex, int itemIndex)
      itemBuilder,
      Widget Function(BuildContext context, int sectionIndex)
      sectionTitleBuilder,
      themeColor,
      dividerThemeColor) {
    final items = <Widget>[];

    for (var sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
      final itemCount = itemCounter(sectionIndex);

      items.add(Theme(
        data: ThemeData(
            textTheme: TextTheme(subtitle1: TextStyle(color: themeColor,fontFamily: 'Lato')),
            backgroundColor: dividerThemeColor,
            unselectedWidgetColor: themeColor,
            accentColor: themeColor)
            .copyWith(dividerColor: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: ListTileTheme(
            contentPadding: EdgeInsets.only(right: 16,top:sectionIndex>0?26:0),
            child: ExpansionTile(
              title: sectionTitleBuilder == null
                  ? Container()
                  : Container(child: buildTitle(items, sectionIndex, context)),
              initiallyExpanded: true,
              children: buildSection(itemCount, items, sectionIndex, context),
            ),
          ),
        ),
      ));

    }

    items.add(StandardListSeparator(padding: EdgeInsets.only(left: 24)));
    return items;
  }

  @override
  Widget buildTitle(
      List<Widget> items, int sectionIndex, BuildContext context) {
    final title = sectionTitleBuilder(context, sectionIndex);
    return title;
  }

  @override
  List<Widget> buildSection(int itemCount, List<Widget> items, int sectionIndex,
      BuildContext context) {
    final List<Widget> section = [];

    for (var itemIndex = 0; itemIndex < itemCount; itemIndex++) {
      final item = itemBuilder(context, sectionIndex, itemIndex);

      section.add(StandardListSeparator());

      section.add(item);

    }
    return section;
  }
}
