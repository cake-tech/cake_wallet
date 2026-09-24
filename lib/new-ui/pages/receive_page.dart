import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/receive/receive_bloc.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/payjoin_copy_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_type_display.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_type_selector.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_address_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_display.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_amount_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_bottom_buttons.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_info_box.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_modal.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_label_widget.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_large_amount_preview.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_qr_code.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_token_display.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/utils/share_util.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ReceivePage extends StatelessWidget {
  const ReceivePage({required this.bloc, super.key});

  final ReceiveBloc bloc;

  @override
  Widget build(BuildContext context) => BlocProvider<ReceiveBloc>(
        create: (_) => bloc,
        child: const _ReceivePageBody(),
      );
}

class _ReceivePageBody extends StatefulWidget {
  const _ReceivePageBody();

  @override
  State<_ReceivePageBody> createState() => _ReceivePageBodyState();
}

class _ReceivePageBodyState extends State<_ReceivePageBody> {
  bool _largeQrMode = false;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceBright,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: BlocPresentationListener<ReceiveBloc, ReceivePresentation>(
            listener: (context, event) => showPopUp<void>(
              context: context,
              builder: (dialogContext) => AlertWithOneAction(
                alertTitle: S.of(dialogContext).error,
                alertContent: event.message,
                buttonText: S.of(dialogContext).ok,
                buttonAction: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            child: BlocBuilder<ReceiveBloc, ReceiveState>(
              builder: (context, state) => switch (state) {
                ReceiveLoading() => const _LoadingWidget(),
                ReceiveFailure() => _FailureWidget(message: state.message),
                ReceiveLoaded() => _LoadedWidget(
                    state: state,
                    largeQrMode: _largeQrMode,
                    onQrTap: () => _toggleLargeQr(context, state),
                  ),
              },
            ),
          ),
        ),
      );

  void _toggleLargeQr(BuildContext context, ReceiveLoaded state) {
    setState(() => _largeQrMode = !_largeQrMode);
    if (!state.isInfoboxDismissed) {
      context.read<ReceiveBloc>().add(const InfoboxDismissed());
    }
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ModalTopBar(
            title: S.of(context).receive,
            leadingIcon: const Icon(Icons.close),
            leadingSemanticLabel: S.of(context).close,
            onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          const Expanded(child: Center(child: CupertinoActivityIndicator(radius: 14))),
        ],
      );
}

class _FailureWidget extends StatelessWidget {
  const _FailureWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModalTopBar(
          title: S.of(context).receive,
          leadingIcon: const Icon(Icons.close),
          leadingSemanticLabel: S.of(context).close,
          onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Text(message),
                TextButton(
                  onPressed: () => context.read<ReceiveBloc>().add(const Init()),
                  child: Text(S.of(context).try_again),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadedWidget extends StatelessWidget {
  const _LoadedWidget({
    required this.state,
    required this.largeQrMode,
    required this.onQrTap,
  });

  final ReceiveLoaded state;
  final bool largeQrMode;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final hasAddressTypeSelector = state.addressTypeOptions.length > 1;
    final hasLabel = state.addressEntry.label != null && state.addressEntry.label!.isNotEmpty;
    final infobox = ReceiveInfoBox.forWalletType(
      context,
      state.walletType,
      supportedCurrencies: state.receivableTokens,
      onDismissed: () => context.read<ReceiveBloc>().add(const InfoboxDismissed()),
      autoGenerateSubaddressStatus: state.isLightning
          ? AutoGenerateSubaddressStatus.disabled
          : context.read<ReceiveBloc>().autoGenerateSubaddressStatus,
      addressRotates:
          state.walletType != WalletType.zcash || zcash!.isRotatingAddressOption(state.addressType),
    );
    final isRotationAvailable = state.hasAddressRotation;

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ModalTopBar(
          title: largeQrMode ? "" : S.of(context).receive,
          leadingIcon: const Icon(Icons.close),
          leadingSemanticLabel: S.of(context).close,
          trailingWidget: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: largeQrMode || isRotationAvailable
                ? ModernButton(
                    key: ValueKey(largeQrMode),
                    size: 36,
                    icon: largeQrMode
                        ? const Icon(Icons.share)
                        : state.isRotatingAddress
                            ? const CupertinoActivityIndicator()
                            : const Icon(Icons.refresh),
                    semanticLabel:
                        largeQrMode ? S.of(context).share_address : S.of(context).rotate_address,
                    onPressed: () {
                      if (largeQrMode) {
                        ShareUtil.share(
                          text: state.paymentUri.toString(),
                          context: context,
                        );
                      } else if (isRotationAvailable) {
                        context.read<ReceiveBloc>().add(const AddressRotated());
                      }
                    },
                  )
                : const SizedBox.shrink(),
          ),
          onLeadingPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              ReceiveAmountDisplay(
                amount: state.requestedAmount,
                fiatEquivalent: state.fiatEquivalent,
                largeQrMode: largeQrMode,
              ),
              ReceiveQrCode(
                qrData: state.paymentUri.toString(),
                embeddedIconAsset: state.qrEmbeddedIcon,
                hasPayjoin: state.hasPayjoin,
                largeQrMode: largeQrMode,
                onTap: onQrTap,
                isFetching: state.isFetchingInvoice,
              ),
              if (state.tokenCurrency != null && !state.isLightning)
                ReceiveTokenDisplay(
                  token: state.tokenCurrency!,
                  walletType: state.walletType,
                ),
              if (hasAddressTypeSelector)
                ReceiveAddressTypeDisplay(
                  selected: state.addressType,
                  walletType: state.walletType,
                  largeQrMode: largeQrMode,
                  onTap: () => _showAddressTypePicker(context, state),
                  isLoading: state.isChangingAddressType,
                ),
              ReceiveAddressWidget(
                address: state.addressEntry.address,
                walletType: state.walletType,
              ),
              // The label chip animates to zero height when there is no
              // label (or in large QR mode); keep it out of the semantics
              // tree entirely while it is collapsed.
              ExcludeSemantics(
                excluding: largeQrMode || !hasLabel,
                child: MergeSemantics(
                  child: Semantics(
                    button: true,
                    hint: S.of(context).set_label,
                    child: GestureDetector(
                      onTap: () => _showLabelModal(context, state),
                      child: ReceiveLabelWidget(
                        label: state.addressEntry.label ?? "",
                        largeQrMode: largeQrMode,
                      ),
                    ),
                  ),
                ),
              ),
              ReceiveBottomButtons(
                largeQrMode: largeQrMode,
                copyData: state.hasPayjoin ? null : ClipboardData(text: _copyText(state)),
                showAddressesButton: state.hasAddressList,
                showLabelButton: state.hasAddressList && !hasLabel,
                onCopyButtonPressed: () => _showPayjoinCopyModal(context, state),
                onAmountButtonPressed: () => _showAmountModal(context, state),
                onLabelButtonPressed: () => _showLabelModal(context, state),
                onAddressesButtonPressed: () => _openAddressesPage(context, state),
              ),
              ReceiveLargeAmountPreview(
                amount: state.requestedAmount,
                largeQrMode: largeQrMode,
              ),
              if (infobox != null && !state.isLightning)
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    heightFactor: state.isInfoboxDismissed ? 0 : 1,
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: state.isInfoboxDismissed ? 0 : 1,
                      curve: Curves.easeOutCubic,
                      child: infobox,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPayjoinCopyModal(BuildContext context, ReceiveLoaded state) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) => PayjoinCopyModal(uri: state.paymentUri),
    );
  }

  String _copyText(ReceiveLoaded state) =>
      state.requestedAmount == null ? state.paymentUri.address : state.paymentUri.toString();

  Future<void> _showLabelModal(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    final label = await showMaterialModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => ReceiveLabelModal(initialLabel: state.addressEntry.label ?? ""),
    );
    if (label != null && !bloc.isClosed) {
      bloc.add(LabelSubmitted(label));
    }
  }

  Future<void> _showAmountModal(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    await showMaterialModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => ReceiveAmountModal(bloc: bloc, amountAtOpen: state.amountInInputCurrency),
    );
  }

  Future<void> _showAddressTypePicker(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    final selected = await showCupertinoModalBottomSheet<ReceivePageOption>(
      context: context,
      barrierColor: Colors.black.withAlpha(80),
      builder: (_) => Material(
        child: ReceiveAddressTypeSelector(
          options: state.addressTypeOptions,
          selected: state.addressType,
          walletType: state.walletType,
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    if (!bloc.isClosed) {
      bloc.add(AddressTypeSelected(selected));
    }
  }

  Future<void> _openAddressesPage(BuildContext context, ReceiveLoaded state) async {
    final bloc = context.read<ReceiveBloc>();
    await Navigator.of(context).pushNamed(Routes.receiveAddresses, arguments: false);
    if (!bloc.isClosed) {
      bloc.add(const AddressesPageClosed());
    }
  }
}
