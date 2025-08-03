import 'dart:async';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/address_book/contact_refresh_page.dart';
import 'package:cake_wallet/src/screens/address_book/contact_welcome_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_address_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_alias_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_contact_page.dart';
import 'package:cake_wallet/src/screens/address_book/contact_page.dart';
import 'package:cake_wallet/src/screens/address_book/edit_new_contact_page.dart';
import 'package:cake_wallet/src/screens/address_book/supported_handles_page.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class AddressBookBottomSheet extends StatefulWidget {
  const AddressBookBottomSheet({
    this.initialRoute,
    this.initialArgs
  });

  final String? initialRoute;
  final Object? initialArgs;

  @override
  State<AddressBookBottomSheet> createState() => _AddressBookBottomSheetState();
}

class _AddressBookBottomSheetState extends State<AddressBookBottomSheet>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenH * 0.45),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(context),
                _AddContactNavigator(
                  initialRoute: widget.initialRoute ?? Navigator.defaultRouteName,
                  initialArgs: widget.initialArgs,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDragHandle(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Row(
      children: [
        const Spacer(flex: 4),
        Expanded(
          flex: 2,
          child: Container(
            height: 4,
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
    required this.initialRoute,
    this.initialArgs
  });

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
    final Widget page = _pageFor(name, args);

    return PageRouteBuilder(
      settings: RouteSettings(name: name, arguments: args),
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  Widget _pageFor(String name, Object? args) {
    switch (name) {
      case Routes.supportedHandlesPage:
        return getIt<SupportedHandlesPage>();
      case Routes.contactWelcomePage:
        return getIt<ContactWelcomePage>(param1: args as ContactRecord?);
      case Routes.editNewContactPage:
        final list = args as List<dynamic>;
        return getIt<EditNewContactPage>(
          param1: list[0] as ParsedAddress,
          param2: list.length > 1 ? list[1] as ContactRecord? : null,
        );
      case Routes.editContactPage:
        final vm = args as ContactViewModel;
        return getIt<EditContactPage>(param1: vm);
      case Routes.editAliasPage:
        final list = args as List<dynamic>;
        return getIt<EditAliasPage>(
          param1: list[0] as ContactViewModel,
          param2: list.length > 1 ? list[1] as String? : '',
        );
      case Routes.contactPage:
        return getIt<ContactPage>(param1: args as ContactRecord);
      case Routes.editAddressPage:
        return getIt<EditAddressPage>(param1: args);

      case Routes.contactRefreshPage:
        final list = args as List<dynamic>;
        final contact = list[0] as ContactRecord;
        final selectedCurrency = list[1] as CryptoCurrency;
        return getIt<ContactRefreshPage>(
          param1: contact,
          param2: selectedCurrency,
        );
      default:
        return getIt<ContactWelcomePage>(param1: args as ContactRecord?);
    }
  }
}
