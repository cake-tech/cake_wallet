import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/src/screens/address_book/sheet_page.dart';
import 'package:cake_wallet/src/screens/address_book/widgets/handles_list_widget.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';

class SupportedHandlesPage extends SheetPage {
  SupportedHandlesPage({required this.contactViewModel});

  final ContactViewModel contactViewModel;

  @override
  String? get title => 'Supported Handles';

  @override
  Widget body(BuildContext context) {
    final selectedInit = <AddressSource>[
      for (final src in supportedSources)
        if (contactViewModel.lookupMap[src.label]!.$1()) src
    ];

    return HandlesListWidget(
      items: supportedSources,
      initiallySelected: selectedInit,
      onSelectionChanged: (sel) {
        for (final src in supportedSources) {
          final pair = contactViewModel.lookupMap[src.label]!;
          pair.$2(sel.contains(src));
        }
      },
    );
  }
}


