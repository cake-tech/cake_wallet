import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/address_book/widgets/grouped_wallet_contacts_tab.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class WalletContactsModalPage extends StatelessWidget {
  const WalletContactsModalPage({required this.onContactTap, super.key});

  final void Function(ContactBase contact) onContactTap;

  @override
  Widget build(BuildContext context) => BlocProvider<WalletContactsCubit>(
        create: (_) => getIt.get<WalletContactsCubit>()..load(),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              ModalTopBar(
                title: S.of(context).wallets,
                leadingIcon: const Icon(Icons.arrow_back),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: BlocBuilder<WalletContactsCubit, WalletContactsState>(
                  builder: (context, state) => GroupedWalletContactsTab(
                    state: state,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
