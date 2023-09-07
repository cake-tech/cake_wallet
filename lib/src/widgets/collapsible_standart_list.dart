import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';

class CollapsibleSectionList extends SectionStandardList {
  CollapsibleSectionList(
      {required int sectionCount,
      required int Function(int sectionIndex) itemCounter,
      required Widget Function(int sectionIndex, int itemIndex) itemBuilder,
      Widget Function(int sectionIndex)? sectionTitleBuilder,
      bool hasTopSeparator = false})
      : super(
            hasTopSeparator: hasTopSeparator,
            sectionCount: sectionCount,
            itemCounter: itemCounter,
            itemBuilder: itemBuilder,
            sectionTitleBuilder: sectionTitleBuilder);

  @override
  Widget buildTitle(List<Widget> items, int sectionIndex) {
    if (sectionTitleBuilder == null) {
      throw Exception('Cannot to build title. sectionTitleBuilder is null');
    }
    return sectionTitleBuilder!.call(sectionIndex);
  }

  @override
  List<Widget> buildSection(int itemCount, List<Widget> items, int sectionIndex) {
    final List<Widget> section = [];

    for (var itemIndex = 0; itemIndex < itemCount; itemIndex++) {
      final item = itemBuilder(sectionIndex, itemIndex);

      section.add(StandardListSeparator());

      section.add(item);
    }
    return section;
  }
}
