import 'dart:async';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/contact_welcome_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_address_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_contact_group_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_contact_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_new_contact_group_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_new_contact_page.dart';
import 'package:cake_wallet/src/screens/address_book/entities/address_edit_request.dart';

import 'package:cake_wallet/src/screens/address_book/supported_handles_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:flutter/material.dart';

class AddressBookBottomSheet extends StatelessWidget {
  const AddressBookBottomSheet({
    super.key,
    required this.onHandlerSearch,
    this.initialRoute,
    this.initialArgs,
  });

  final Future<List<ParsedAddress>> Function(String q) onHandlerSearch;
  final String? initialRoute;
  final Object? initialArgs;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(context),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .7,
              ),
              child: _AddContactNavigator(
                onHandlerSearch: onHandlerSearch,
                initialRoute: initialRoute ?? Navigator.defaultRouteName,
                initialArgs: initialArgs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDragHandle(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        const Spacer(flex: 4),
        Expanded(
          flex: 2,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const Spacer(flex: 4),
      ],
    ),
  );
}

class _AddContactNavigator extends StatelessWidget {
  const _AddContactNavigator({
    required this.onHandlerSearch,
    required this.initialRoute,
    this.initialArgs,
  });

  final Future<List<ParsedAddress>> Function(String) onHandlerSearch;
  final String initialRoute;
  final Object? initialArgs;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (_, __) => [
        _routeFor(initialRoute, initialArgs),
      ],
      onGenerateRoute: (settings) => _routeFor(
        settings.name ?? Navigator.defaultRouteName,
        settings.arguments,
      ),
    );
  }

  Route<dynamic> _routeFor(String name, Object? args) {
    late final Widget page;

    switch (name) {
      case Routes.supportedHandlesPage:
        page = getIt<SupportedHandlesPage>();
        break;
      case Routes.newContactWelcomePage:
        final list = args as List<dynamic>;
        final onSearch = list[0] as Future<List<ParsedAddress>> Function(String);
        final handleOnly = list.length > 1 && list[1] == true;
        final contact = list.length > 2 ? list[2] as ContactRecord? : null;

        page = NewContactWelcomePage(
          onSearch: onSearch,
          handleOnly: handleOnly,
          existingContact: contact,
        );
        break;
      case Routes.editNewContactGroupPage:
        final list = args as List<dynamic>;
        page = getIt<EditNewContactGroupPage>(
          param1: list[0] as ParsedAddress,
          param2: list.length > 1 ? list[1] as ContactRecord? : null,
        );
        break;
      case Routes.editContactGroupPage:
        final vm = args as ContactViewModel;
        page = getIt<EditContactGroupPage>(param1: vm);
        break;
      case Routes.editNewContactPage:
        page = getIt<EditNewContactPage>(param1: args as ContactRecord);
        break;
      case Routes.editContactPage:
        page = getIt<EditContactPage>(param1: args as ContactRecord);
        break;
      case Routes.editAddressPage:
        page = getIt<EditAddressPage>(param1: args as AddressEditRequest);
        break;
      default:
        page = NewContactWelcomePage(onSearch: onHandlerSearch, handleOnly: false);
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: RouteSettings(name: name, arguments: args),
    );
  }
}
