import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/receive/widgets/receive_label_modal.dart";
import "package:cake_wallet/new-ui/viewmodels/addresses/addresses_bloc.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key, this.showHidden = false});

  final bool showHidden;

  @override
  Widget build(BuildContext context) => BlocProvider<AddressesBloc>(
      create: (_) => getIt<AddressesBloc>(param1: showHidden),
      child: const _AddressesPageBody(),
    );
}

class _AddressesPageBody extends StatelessWidget {
  const _AddressesPageBody();

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: BlocBuilder<AddressesBloc, AddressesState>(
          builder: (context, state) => switch (state) {
            AddressesLoading() => const _LoadingWidget(),
            AddressesFailure() => _FailureWidget(code: state.code),
            AddressesLoaded() => _LoadedWidget(state: state),
          },
        ),
      ),
    );
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Column(
      children: [
        _TopBar(title: S.of(context).addresses),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
}

class _FailureWidget extends StatelessWidget {
  const _FailureWidget({required this.code});

  final AddressesFailureCode code;

  @override
  Widget build(BuildContext context) => Column(
      children: [
        _TopBar(title: S.of(context).addresses),
        Expanded(child: Center(child: Text(S.of(context).error_dialog_content))),
      ],
    );
}

class _LoadedWidget extends StatelessWidget {
  const _LoadedWidget({required this.state});

  final AddressesLoaded state;

  @override
  Widget build(BuildContext context) {
    final title = state.showHidden ? S.of(context).hidden_addresses : S.of(context).addresses;
    final groups = state.displayableGroups;

    return Column(
      children: [
        _TopBar(title: title),
        _SearchBar(
          initial: state.searchTerm,
          onChanged: (t) => context.read<AddressesBloc>().add(SearchTermEntered(t)),
        ),
        if (state.hasAccounts && state.currentAccount != null)
          _AccountHeader(label: state.currentAccount!.label),
        Expanded(
          child: groups.isEmpty
              ? Center(child: Text(S.of(context).csv_nothing_to_export))
              : ListView.builder(
                  itemCount: _flattenedLength(groups),
                  itemBuilder: (context, i) => _rowAt(context, groups, i),
                ),
        ),
        if (state.showAddManualAddresses && !state.showHidden)
          _BottomActionButton(
            label: S.of(context).add_account,
            onPressed: () => _promptAddAddress(context),
          ),
        if (!state.showHidden)
          _BottomActionButton(
            label: S.of(context).show_hidden_addresses,
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.receiveAddresses,
              arguments: true,
            ),
          ),
      ],
    );
  }

  int _flattenedLength(List<AddressGroup> groups) {
    var count = 0;
    for (final g in groups) {
      if (g.header != null) {
        count += 1;
      }
      count += g.entries.length;
    }
    return count;
  }

  Widget _rowAt(BuildContext context, List<AddressGroup> groups, int index) {
    var i = 0;
    for (final g in groups) {
      if (g.header != null) {
        if (i == index) {
          return _GroupHeader(header: g.header!);
        }
        i += 1;
      }
      for (final entry in g.entries) {
        if (i == index) {
          return _AddressRow(
            entry: entry,
            walletType: state.walletType,
            isActive: entry.address == state.activeAddress,
            onTap: () => context.read<AddressesBloc>().add(ActiveAddressSet(entry.address)),
            onLongPress: () => _showRowMenu(context, entry),
          );
        }
        i += 1;
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _promptAddAddress(BuildContext context) async {
    final bloc = context.read<AddressesBloc>();
    await showMaterialModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => ReceiveLabelModal(
        initialLabel: "",
        onSubmit: (label) async => bloc.add(AddressAdded(label)),
      ),
    );
  }

  Future<void> _showRowMenu(BuildContext context, AddressEntry entry) async {
    final bloc = context.read<AddressesBloc>();
    final action = await showModalBottomSheet<_RowAction>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(S.of(context).address_label),
              onTap: () => Navigator.of(context).pop(_RowAction.editLabel),
            ),
            ListTile(
              leading: Icon(entry.isHidden ? Icons.visibility : Icons.visibility_off),
              title:
                  Text(entry.isHidden ? S.of(context).unhide_address : S.of(context).hide_address),
              onTap: () => Navigator.of(context).pop(_RowAction.toggleHide),
            ),
            if (entry.isOneTimeReceiveAddress)
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(S.of(context).delete),
                onTap: () => Navigator.of(context).pop(_RowAction.delete),
              ),
          ],
        ),
      ),
    );

    switch (action) {
      case _RowAction.editLabel:
        if (context.mounted) {
          await showMaterialModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withAlpha(80),
            builder: (_) => ReceiveLabelModal(
              initialLabel: entry.label ?? "",
              onSubmit: (label) async => bloc.add(AddressLabelSet(entry.address, label)),
            ),
          );
        }
      case _RowAction.toggleHide:
        bloc.add(AddressHideToggled(entry.address, hidden: !entry.isHidden));
      case _RowAction.delete:
        bloc.add(AddressDeleted(entry.address));
      case null:
        break;
    }
  }
}

enum _RowAction { editLabel, toggleHide, delete }

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => ModalTopBar(
      title: title,
      leadingIcon: const Icon(Icons.close),
      onLeadingPressed: Navigator.of(context).pop,
      onTrailingPressed: () {},
    );
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: S.of(context).search,
            border: InputBorder.none,
            icon: const Icon(Icons.search),
          ),
        ),
      ),
    );
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            S.of(context).account,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.header});

  final AddressGroupHeader header;

  @override
  Widget build(BuildContext context) {
    final text = switch (header) {
      HiddenAddressesHeader() => S.of(context).hidden_addresses,
      AccountsHeader() => S.of(context).account,
      RegularAddressesHeader() => S.of(context).addresses,
      SilentPaymentsReceivedHeader() => S.of(context).received,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.entry,
    required this.walletType,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  final AddressEntry entry;
  final WalletType walletType;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final label = entry.label ?? "";
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  AddressFormatter.buildSegmentedAddress(
                    address: entry.address,
                    walletType: walletType,
                    evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 13,
                          fontFamily: "IBM Plex Mono",
                        ),
                  ),
                  if (entry.balance != null && entry.balance!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.balance!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(onPressed: onPressed, child: Text(label)),
      ),
    );
}
