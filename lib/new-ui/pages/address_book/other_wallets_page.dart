import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/legacy_wallet_contacts_tab.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class OtherWalletsPage extends BasePage {
  OtherWalletsPage({required this.onContactTap});

  final void Function(ContactBase contact) onContactTap;

  @override
  String get title => S.current.other_wallets;

  @override
  bool get gradientBackground => true;

  @override
  Widget body(BuildContext context) => BlocBuilder<WalletContactsCubit, WalletContactsState>(
    builder: (context, state) =>
        LegacyWalletContactsTab(state: state, onContactTap: onContactTap),
  );

  static Future<void> show(
      BuildContext context, {
        required void Function(ContactBase contact) onContactTap,
      }) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: context.read<WalletContactsCubit>(),
            child: OtherWalletsPage(onContactTap: onContactTap),
          ),
        ),
      );
}