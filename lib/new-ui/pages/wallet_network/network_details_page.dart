import "dart:async";

import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/wallet_network/network_page_scaffold.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/network_details_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class NetworkDetailsPage extends StatelessWidget {
  const NetworkDetailsPage({required this.bloc, super.key});

  final NetworkDetailsBloc bloc;

  @override
  Widget build(BuildContext context) => BlocProvider<NetworkDetailsBloc>(
        create: (_) => bloc,
        child: const _NetworkDetailsBody(),
      );
}

class _NetworkDetailsBody extends StatefulWidget {
  const _NetworkDetailsBody();

  @override
  State<_NetworkDetailsBody> createState() => _NetworkDetailsBodyState();
}

class _NetworkDetailsBodyState extends State<_NetworkDetailsBody> {
  final Map<NetworkField, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<NetworkDetailsBloc>().state;
    for (final field in NetworkField.values) {
      _controllers[field] = TextEditingController(text: state.value(field));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocPresentationListener<NetworkDetailsBloc, NetworkDetailsPresentation>(
      listener: _onPresentation,
      child: BlocBuilder<NetworkDetailsBloc, NetworkDetailsState>(
        builder: (context, state) => NetworkPageScaffold(
          title: state.mode == NetworkDetailsMode.manualAdd
              ? S.of(context).add_network
              : S.of(context).network_details,
          body: SingleChildScrollView(
            key: const ValueKey("network_details_scrollable_key"),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: _NetworkDetailsForm(state: state, controllers: _controllers),
          ),
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: _Buttons(state: state, onDelete: _confirmDelete),
          ),
        ),
      ),
    );
  }

  void _onPresentation(BuildContext context, NetworkDetailsPresentation event) {
    switch (event) {
      case NetworkDetailsSaved():
      case NetworkDetailsDeleted():
        Navigator.of(context).pop(true);
      case NetworkDetailsFieldsFilled():
        for (final entry in event.values.entries) {
          _controllers[entry.key]?.text = entry.value;
        }
      case BorrowedTickerConfirmationRequested():
        unawaited(_confirmBorrowedTicker(event));
      case NetworkDetailsFailed():
        unawaited(
          showPopUp<void>(
            context: context,
            builder: (dialogContext) => AlertWithOneAction(
              alertTitle: S.of(dialogContext).error,
              alertContent: event.message,
              buttonText: S.of(dialogContext).ok,
              buttonAction: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
    }
  }

  Future<void> _confirmBorrowedTicker(BorrowedTickerConfirmationRequested event) async {
    final isConfirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertWithTwoActions(
          alertTitle: S.of(dialogContext).warning,
          alertContent: S
              .of(dialogContext)
              .added_network_borrowed_ticker_warning(event.networkName, event.symbol),
          leftButtonText: S.of(dialogContext).cancel,
          rightButtonText: S.of(dialogContext).continue_text,
          alertLeftActionButtonKey:
              const ValueKey("network_details_borrowed_ticker_cancel_button_key"),
          alertRightActionButtonKey:
              const ValueKey("network_details_borrowed_ticker_continue_button_key"),
          leftAlertButtonStyle: AlertButtonStyle(
            backgroundColor: colors.primary,
            textColor: colors.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
          actionLeftButton: () => Navigator.of(dialogContext).pop(false),
          actionRightButton: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );

    if (!mounted) {
      return;
    }

    // Dismissing the popup any other way counts as Cancel
    context
        .read<NetworkDetailsBloc>()
        .add(BorrowedTickerConfirmationAnswered(isConfirmed: isConfirmed == true));
  }

  Future<void> _confirmDelete() async {
    final bloc = context.read<NetworkDetailsBloc>();
    final name = bloc.network?.name ?? "";

    await showPopUp<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        const nameMarker = "\u0000";
        final parts = S.of(dialogContext).delete_network_warning(nameMarker).split(nameMarker);
        final bodyStyle = Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
              letterSpacing: -0.07,
              decoration: TextDecoration.none,
            );

        return AlertWithTwoActions(
          alertTitle: S.of(dialogContext).delete_network_warning_title,
          alertContent: S.of(dialogContext).delete_network_warning(name),
          alertContentTextWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: parts.first),
                for (final part in parts.skip(1)) ...[
                  TextSpan(text: name, style: bodyStyle?.copyWith(color: colors.primary)),
                  TextSpan(text: part),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            style: bodyStyle,
          ),
          leftButtonText: S.of(dialogContext).cancel,
          rightButtonText: S.of(dialogContext).continue_text,
          alertLeftActionButtonKey: const ValueKey("network_details_delete_cancel_button_key"),
          alertRightActionButtonKey: const ValueKey("network_details_delete_continue_button_key"),
          leftAlertButtonStyle: AlertButtonStyle(
            backgroundColor: colors.primary,
            textColor: colors.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
          actionLeftButton: () => Navigator.of(dialogContext).pop(),
          actionRightButton: () {
            Navigator.of(dialogContext).pop();
            bloc.add(const NetworkDeleteConfirmed());
          },
        );
      },
    );
  }
}

class _NetworkDetailsForm extends StatelessWidget {
  const _NetworkDetailsForm({required this.state, required this.controllers});

  final NetworkDetailsState state;
  final Map<NetworkField, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noteStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          letterSpacing: -0.06,
        );
    final isManual = state.mode != NetworkDetailsMode.chainList;
    final network = context.read<NetworkDetailsBloc>().network;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        if (!isManual && network != null)
          Center(
            child: CakeImageWidget(
              imageUrl: network.iconUrl,
              width: 50,
              height: 50,
              isRoundedSquare: true,
              isOutlined: true,
              fallbackName: network.name,
            ),
          ),
        _NetworkDetailsField(
          field: NetworkField.name,
          label: S.of(context).network_name,
          state: state,
          controller: controllers[NetworkField.name]!,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _NetworkDetailsField(
              field: NetworkField.rpcUrl,
              label: S.of(context).rpc_url,
              state: state,
              controller: controllers[NetworkField.rpcUrl]!,
              trailing: state.isFailoverRevealed || state.isReadOnly(NetworkField.failoverUrl)
                  ? null
                  : _FailoverButton(
                      onPressed: () =>
                          context.read<NetworkDetailsBloc>().add(const FailoverUrlRevealed()),
                    ),
            ),
            if (state.isFailoverRevealed)
              _NetworkDetailsField(
                field: NetworkField.failoverUrl,
                label: S.of(context).failover_url,
                state: state,
                controller: controllers[NetworkField.failoverUrl]!,
              ),
            if (state.isReadOnly(NetworkField.rpcUrl))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  S.of(context).nodes_managed_from_wallet_settings,
                  key: const ValueKey("network_details_nodes_managed_text_key"),
                  style: noteStyle,
                ),
              ),
          ],
        ),
        _NetworkDetailsField(
          field: NetworkField.chainId,
          label: S.of(context).chain_id,
          state: state,
          controller: controllers[NetworkField.chainId]!,
        ),
        _NetworkDetailsField(
          field: NetworkField.symbol,
          label: S.of(context).symbol,
          state: state,
          controller: controllers[NetworkField.symbol]!,
        ),
        _NetworkDetailsField(
          field: NetworkField.explorerUrl,
          label: S.of(context).block_explorer_url,
          state: state,
          controller: controllers[NetworkField.explorerUrl]!,
        ),
        if (isManual)
          _NetworkDetailsField(
            field: NetworkField.iconUrl,
            label: S.of(context).icon_url,
            state: state,
            controller: controllers[NetworkField.iconUrl]!,
            leading: _IconUrlPreview(
              url: _tryIconPreviewUrl(state.value(NetworkField.iconUrl)),
              name: state.value(NetworkField.name),
            ),
          ),
      ],
    );
  }

  static String? _tryIconPreviewUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == "https" && uri.host.contains(".") ? value.trim() : null;
  }
}

class _IconUrlPreview extends StatefulWidget {
  const _IconUrlPreview({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  State<_IconUrlPreview> createState() => _IconUrlPreviewState();
}

class _IconUrlPreviewState extends State<_IconUrlPreview> {
  // Fetch only once typing pauses, not one request per keystroke
  static const _typingPause = Duration(milliseconds: 500);

  String? _previewUrl;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.url;
  }

  @override
  void didUpdateWidget(_IconUrlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url == oldWidget.url) {
      return;
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(_typingPause, () => setState(() => _previewUrl = widget.url));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CakeImageWidget(
        imageUrl: _previewUrl,
        width: 40,
        height: 40,
        isRoundedSquare: true,
        isOutlined: true,
        fallbackName: widget.name,
      );
}

class _NetworkDetailsField extends StatelessWidget {
  const _NetworkDetailsField({
    required this.field,
    required this.label,
    required this.state,
    required this.controller,
    this.trailing,
    this.leading,
  });

  final NetworkField field;
  final String label;
  final NetworkDetailsState state;
  final TextEditingController controller;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final error = state.errors[field];
    final isReadOnly = state.isReadOnly(field);
    final valueStyle = textTheme.bodyMedium?.copyWith(
      color: isReadOnly ? colors.onSurfaceVariant : colors.onSurface,
      letterSpacing: -0.07,
    );

    final input = Container(
      key: ValueKey("network_details_${field.name}_field_key"),
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isReadOnly
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                state.value(field),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            )
          : TextFormField(
              controller: controller,
              onChanged: (value) => _onChanged(context, value),
              style: valueStyle,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: -0.06,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Semantics(
          label: label,
          child: leading == null
              ? input
              : Row(
                  spacing: 12,
                  children: [leading!, Expanded(child: input)],
                ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              error,
              key: ValueKey("network_details_${field.name}_error_key"),
              style: textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }

  void _onChanged(BuildContext context, String value) {
    if (field == NetworkField.symbol && value != value.toUpperCase()) {
      controller.value = controller.value.copyWith(text: value.toUpperCase());
    }

    context.read<NetworkDetailsBloc>().add(NetworkFieldChanged(field, controller.text));
  }
}

class _FailoverButton extends StatelessWidget {
  const _FailoverButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        key: const ValueKey("network_details_reveal_failover_button_key"),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          S.of(context).failover_url,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: -0.06,
              ),
        ),
      );
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.state, required this.onDelete});

  final NetworkDetailsState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bloc = context.read<NetworkDetailsBloc>();
    final name = bloc.network?.name ?? "";
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.07,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (state.mode == NetworkDetailsMode.chainList && bloc.canResetToDefault)
          NewPrimaryButton(
            key: const ValueKey("network_details_reset_button_key"),
            onPressed: () => bloc.add(const ResetToDefaultRequested()),
            text: S.of(context).reset_to_default,
            color: colors.surfaceContainer,
            textColor: colors.primary,
            labelStyle: labelStyle,
          ),
        NewPrimaryButton(
          key: const ValueKey("network_details_save_button_key"),
          onPressed: () => bloc.add(const NetworkSaveRequested()),
          text: S.of(context).save,
          color: colors.primary,
          textColor: colors.onPrimary,
          labelStyle: labelStyle,
          isLoading: state.isSaving,
          disabled: !state.hasUsageCounts || state.isSaving,
        ),
        if (state.mode == NetworkDetailsMode.manualEdit) ...[
          NewPrimaryButton(
            key: const ValueKey("network_details_delete_button_key"),
            onPressed: onDelete,
            text: S.of(context).delete_network,
            color: colors.surfaceContainer,
            textColor: colors.error,
            borderColor: colors.error,
            labelStyle: labelStyle,
            disabled: !state.canDelete,
          ),
          if (state.hasUsageCounts && !state.canDelete)
            Text(
              S.of(context).network_used_cannot_delete(
                    name,
                    state.walletCount.toString(),
                    state.contactCount.toString(),
                  ),
              key: const ValueKey("network_details_delete_refused_text_key"),
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ],
    );
  }
}
