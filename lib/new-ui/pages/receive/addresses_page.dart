import "dart:ui";

import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_text_field.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/long_press_popup.dart";
import "package:cake_wallet/new-ui/viewmodels/addresses/addresses_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/long_press_menu.dart";
import "package:cake_wallet/new-ui/widgets/receive/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/debounce.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key, this.showHidden = false, this.onSelect});

  final bool showHidden;
  final void Function(String address)? onSelect;

  @override
  Widget build(BuildContext context) => BlocProvider<AddressesBloc>(
        create: (_) => getIt<AddressesBloc>(param1: showHidden),
        child: _AddressesPageBody(onSelect: onSelect),
      );
}

class _AddressesPageBody extends StatelessWidget {
  const _AddressesPageBody({this.onSelect});

  final void Function(String address)? onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: BlocConsumer<AddressesBloc, AddressesState>(
          listenWhen: (previous, current) {
            final prev = previous is AddressesLoaded ? previous.failureCode : null;
            final curr = current is AddressesLoaded ? current.failureCode : null;
            return curr != null && curr != prev;
          },
          listener: (context, state) {
            if (state is! AddressesLoaded || state.failureCode == null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(S.of(context).error_dialog_content)));
          },
          builder: (context, state) => switch (state) {
            AddressesLoading() => const _LoadingWidget(),
            AddressesFailure() => const _FailureWidget(),
            AddressesLoaded() => _LoadedWidget(state: state, onSelect: onSelect),
          },
        ),
      );
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12,
        children: [
          _TopBar(title: S.of(context).addresses),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
}

class _FailureWidget extends StatelessWidget {
  const _FailureWidget();

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12,
        children: [
          _TopBar(title: S.of(context).addresses),
          Expanded(child: Center(child: Text(S.of(context).error_dialog_content))),
        ],
      );
}

class _LoadedWidget extends StatefulWidget {
  const _LoadedWidget({required this.state, this.onSelect});

  final AddressesLoaded state;
  final void Function(String address)? onSelect;

  @override
  State<_LoadedWidget> createState() => _LoadedWidgetState();
}

class _LoadedWidgetState extends State<_LoadedWidget> {
  late final TextEditingController _searchController;
  final _searchDebounce = Debounce(const Duration(milliseconds: 200));

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchTerm)
      ..addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _LoadedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.walletId != oldWidget.state.walletId &&
        widget.state.searchTerm != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.state.searchTerm,
        selection: TextSelection.collapsed(offset: widget.state.searchTerm.length),
      );
    }
  }

  void _onSearchChanged() {
    final term = _searchController.text;
    _searchDebounce.run(() {
      if (!mounted) {
        return;
      }
      context.read<AddressesBloc>().add(SearchTermEntered(term));
    });
  }

  @override
  void dispose() {
    _searchDebounce.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  bool get _isPicker => widget.onSelect != null;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final title = state.showHidden ? S.of(context).hidden_addresses : S.of(context).addresses;
    final groups = state.displayableGroups;

    return Column(
      spacing: 12,
      children: [
        _TopBar(title: title),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                controller: ModalScrollController.of(context),
                slivers: [
                  if (!state.showHidden)
                    SliverToBoxAdapter(
                      child: Column(
                        spacing: 16,
                        children: [
                          if (state.hasAccounts)
                            _AccountPreviewHeader(
                              walletName: state.walletName,
                              accountLabel: state.accountLabel,
                            ),
                          Text(
                            S.of(context).long_press_edit_address,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!_isPicker && state.showAddManualAddresses)
                            const _AddManualAddressButton(),
                          if (!_isPicker && state.hasHiddenAddresses)
                            const _ShowHiddenButton(),
                        ],
                      ),
                    ),
                  if (!state.showHidden && !state.hasHiddenAddresses)
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  for (var i = 0; i < groups.length; i++)
                    _GroupSection(
                      group: groups[i],
                      state: state,
                      isFirstGroup: i == 0,
                      isLast: i == groups.length - 1,
                      isPicker: _isPicker,
                      onEntrySelected: _handleEntrySelected,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 72)),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: _AddressSearchBox(controller: _searchController),
                ),
              ),
              if (state.isSaving)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
                      child: const Center(child: CupertinoActivityIndicator(radius: 14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleEntrySelected(BuildContext context, String address) {
    if (_isPicker) {
      widget.onSelect!(address);
    } else {
      context.read<AddressesBloc>().add(ActiveAddressSet(address));
    }
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.state,
    required this.isFirstGroup,
    required this.isLast,
    required this.isPicker,
    required this.onEntrySelected,
  });

  final AddressGroup group;
  final AddressesLoaded state;
  final bool isFirstGroup;
  final bool isLast;
  final bool isPicker;
  final void Function(BuildContext context, String address) onEntrySelected;

  @override
  Widget build(BuildContext context) {
    if (group.entries.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        if (group.header != null)
          SliverToBoxAdapter(child: _GroupHeader(header: group.header!)),
        SliverPadding(
          padding: EdgeInsets.only(bottom: isLast ? 64 : 12),
          sliver: SliverList.separated(
            itemCount: group.entries.length,
            itemBuilder: (context, index) {
              final entry = group.entries[index];
              return _AddressRow(
                entry: entry,
                selected: entry.address == state.activeAddress && !isPicker,
                first: isFirstGroup &&
                    index == 0 &&
                    (state.showHidden || !state.hasHiddenAddresses),
                last: index == group.entries.length - 1,
                walletType: state.walletType,
                hasBalance: state.hasBalance,
                hasReceived: state.hasReceived,
                canSetLabel: state.canSetLabel,
                canHide: state.canHide,
                isPicker: isPicker,
                onSelect: () => onEntrySelected(context, entry.address),
                onLabelChanged: () {},
                onAddressHidden: () => context
                    .read<AddressesBloc>()
                    .add(AddressHideToggled(entry.address, hidden: !entry.isHidden)),
              );
            },
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.header});

  final AddressGroupHeader header;

  String _title(BuildContext context) => switch (header) {
        SilentPaymentsReceivedHeader() => S.of(context).received,
        RegularAddressesHeader() => S.of(context).addresses,
        HiddenAddressesHeader() => S.of(context).hidden_addresses,
        AccountsHeader() => S.of(context).accounts,
      };

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _title(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
}

class _AddManualAddressButton extends StatelessWidget {
  const _AddManualAddressButton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          child: InkWell(
            onTap: () {
              final bloc = context.read<AddressesBloc>();
              showPopUp<String>(
                context: context,
                builder: (_) => _AddressLabelInputPopup(
                  initialLabel: "",
                  onSaved: (value) => bloc.add(AddressAdded(value)),
                ),
              );
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.of(context).add_address),
                    Icon(
                      Icons.add,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => ModalTopBar(
        title: title,
        leadingIcon: const Icon(Icons.arrow_back),
        onLeadingPressed: Navigator.of(context).pop,
        onTrailingPressed: () {},
      );
}

class _AddressSearchBox extends StatelessWidget {
  const _AddressSearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(128),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  borderRadius: BorderRadius.circular(99999),
                ),
                child: BaseTextFormField(
                  controller: controller,
                  hintText: S.of(context).search,
                  placeholderTextStyle: const TextStyle(fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(99999),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AccountPreviewHeader extends StatefulWidget {
  const _AccountPreviewHeader({required this.walletName, required this.accountLabel});

  final String walletName;
  final String accountLabel;

  @override
  State<_AccountPreviewHeader> createState() => _AccountPreviewHeaderState();
}

class _AccountPreviewHeaderState extends State<_AccountPreviewHeader> {
  final DashboardViewModel dashboardViewModel = getIt<DashboardViewModel>();
  CardDesign? design;
  ReactionDisposer? _designDisposer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _designDisposer = reaction<CardDesign?>(
        (_) => dashboardViewModel.cardDesigns.isNotEmpty
            ? dashboardViewModel.cardDesigns.first
            : null,
        (value) {
          if (mounted) {
            setState(() => design = value);
          }
        },
        fireImmediately: true,
      );
    });
  }

  @override
  void dispose() {
    _designDisposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Observer(
                    builder: (_) => BalanceCard(
                      borderRadius: 5,
                      width: 50,
                      design: design ?? CardDesign.genericDefault,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.accountLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        widget.walletName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  Container(
                    width: 1,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                  ),
                  Observer(
                    builder: (_) => Text(
                      dashboardViewModel.balanceViewModel.balances.isNotEmpty
                          ? dashboardViewModel
                              .balanceViewModel.balances.values.first.availableBalance
                          : "",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ShowHiddenButton extends StatelessWidget {
  const _ShowHiddenButton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Material(
              child: InkWell(
                onTap: () async {
                  final bloc = context.read<AddressesBloc>();
                  await Navigator.of(context)
                      .pushNamed(Routes.receiveAddresses, arguments: true);
                  bloc.add(const AddressListRefreshed());
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.of(context).show_hidden_addresses),
                        const RotatedBox(
                          quarterTurns: 1,
                          child: CakeImageWidget(imageUrl: "assets/new-ui/dropdown_arrow.svg"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ],
        ),
      );
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.entry,
    required this.selected,
    required this.first,
    required this.last,
    required this.walletType,
    required this.hasBalance,
    required this.hasReceived,
    required this.canSetLabel,
    required this.canHide,
    required this.isPicker,
    required this.onSelect,
    required this.onLabelChanged,
    required this.onAddressHidden,
  });

  final AddressEntry entry;
  final bool selected;
  final bool first;
  final bool last;
  final WalletType walletType;
  final bool hasBalance;
  final bool hasReceived;
  final bool canSetLabel;
  final bool canHide;
  final bool isPicker;
  final VoidCallback onSelect;
  final VoidCallback onLabelChanged;
  final VoidCallback onAddressHidden;

  @override
  Widget build(BuildContext context) {
    final hasLabel = entry.label != null && entry.label!.isNotEmpty;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(first ? 16 : 0),
          bottom: Radius.circular(last ? 16 : 0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      if (hasLabel)
                        Text(
                          entry.label!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Expanded(
                        child: AddressFormatter.buildSegmentedAddress(
                          address: entry.address,
                          walletType: walletType,
                          textAlign: TextAlign.left,
                          evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: hasLabel
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                          shouldTruncate: hasLabel,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${S.of(context).transactions}: ${entry.txCount ?? 0}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        "${hasReceived ? S.of(context).received : S.of(context).balance}: ${entry.balance ?? ""}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected) const CakeImageWidget(imageUrl: "assets/new-ui/checkmark.svg"),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isPicker
            ? row
            : LongPressPopupBuilder(
                popup: LongPressMenu(
                  items: [
                    if (canSetLabel)
                      LongPressMenuItem(
                        label: S.of(context).set_label,
                        iconPath: "assets/new-ui/address_set_label.svg",
                        onSelected: () async {
                          final bloc = context.read<AddressesBloc>();
                          Navigator.of(context, rootNavigator: true).pop();
                          final res = await showPopUp<String>(
                            context: context,
                            builder: (_) => _AddressLabelInputPopup(
                              initialLabel: entry.label ?? "",
                              onSaved: (label) =>
                                  bloc.add(AddressLabelSet(entry.address, label)),
                            ),
                          );
                          if (res != null) {
                            onLabelChanged();
                          }
                        },
                      ),
                    if (canHide)
                      LongPressMenuItem(
                        label: entry.isHidden
                            ? S.of(context).unhide_address
                            : S.of(context).hide_address,
                        iconPath: "assets/new-ui/address_hide.svg",
                        onSelected: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          onAddressHidden();
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    LongPressMenuItem(
                      label: S.of(context).show_details,
                      iconPath: "assets/images/info_icon.svg",
                      onSelected: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        await showPopUp<void>(
                          context: context,
                          builder: (context) => _AddressInfoPopup(entry: entry),
                        );
                      },
                    ),
                  ],
                ),
                child: row,
              ),
      ),
    );
  }
}

class _AddressLabelInputPopup extends StatefulWidget {
  const _AddressLabelInputPopup({required this.initialLabel, required this.onSaved});

  final String initialLabel;
  final void Function(String label) onSaved;

  @override
  State<_AddressLabelInputPopup> createState() => _AddressLabelInputPopupState();
}

class _AddressLabelInputPopupState extends State<_AddressLabelInputPopup> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: NewListSections(
                sections: {
                  "": [
                    ListItemTextField(
                      keyValue: "label",
                      label: S.of(context).label,
                      focusNode: _focusNode,
                      onFieldSubmitted: (value) {
                        widget.onSaved(value);
                        Navigator.of(context).pop(value);
                      },
                    ),
                  ],
                },
                controllers: {"label": _controller},
              ),
            ),
          ],
        ),
      );
}

class _AddressInfoPopup extends StatelessWidget {
  const _AddressInfoPopup({required this.entry});

  final AddressEntry entry;

  @override
  Widget build(BuildContext context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadiusGeometry.lerp(
                  BorderRadius.circular(12),
                  BorderRadius.circular(24),
                  0.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.id != null)
                      Text("${S.of(context).address_index}: ${entry.id}"),
                    if (entry.id != null &&
                        entry.derivationPath != null &&
                        entry.derivationPath!.isNotEmpty)
                      const SizedBox(height: 16),
                    if (entry.derivationPath != null && entry.derivationPath!.isNotEmpty)
                      Text("${S.of(context).derivationpath}: ${entry.derivationPath}"),
                    if (entry.id == null &&
                        (entry.derivationPath == null || entry.derivationPath!.isEmpty))
                      Text(S.of(context).nothing_to_display),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
