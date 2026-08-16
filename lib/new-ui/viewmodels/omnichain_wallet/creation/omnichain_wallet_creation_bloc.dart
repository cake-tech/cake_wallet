import "package:bloc/bloc.dart";
import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart";
import "package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_state.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/wallet_type.dart";

class OmniChainWalletBloc extends Bloc<OmniChainWalletEvent, WalletCreationState> {
  OmniChainWalletBloc({
    required this.allWalletTypes,
    required this.creationService,
  }) : super(WalletCreationChainSelection(allWalletTypes: allWalletTypes)) {
    on<OmniChainWalletTypeToggled>(_onWalletTypeToggled);
    on<OmniChainWalletTypesDeselected>(_onWalletTypesDeselected);
    on<OmniChainWalletTypesSelected>(_onWalletTypesSelected);
    on<OmniChainWalletChainSelectionConfirmed>(_onChainSelectionConfirmed);
    on<OmniChainWalletChainSelectionReopened>(_onChainSelectionReopened);
    on<OmniChainWalletGroupNameChanged>(_onGroupNameChanged);
    on<OmniChainWalletGroupNameGenerated>(_onGroupNameGenerated);
    on<OmniChainWalletTestnetToggled>(_onTestnetToggled);
    on<OmniChainWalletZcashNetworkChanged>(_onZcashNetworkChanged);
    on<OmniChainWalletCredentialsSubmitted>(_onCredentialsSubmitted);
    on<OmniChainWalletSummaryConfirmed>(_onSummaryConfirmed);
    on<OmniChainWalletPrimaryTypeSelected>(_onPrimaryTypeSelected);
    on<OmniChainWalletGroupCreateRequested>(_onGroupCreateRequested);
  }

  final Set<WalletType> allWalletTypes;
  final OmniChainWalletCreationService creationService;

  // ---- Step 1: chain selection ----

  void _onWalletTypeToggled(OmniChainWalletTypeToggled event, Emitter<WalletCreationState> emit) {
    final current = state;
    if (current is! WalletCreationChainSelection) return;

    final updatedSelectedTypes = current.selectedTypes;

    if (event.isSelected) {
      updatedSelectedTypes.add(event.type);
    } else {
      updatedSelectedTypes.remove(event.type);
    }

    emit(current.copyWith(selectedTypes: updatedSelectedTypes));
  }

  void _onWalletTypesDeselected(
    OmniChainWalletTypesDeselected event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationChainSelection) {
      return;
    }

    emit(current.copyWith(selectedTypes: <WalletType>{}));
  }

  void _onWalletTypesSelected(
      OmniChainWalletTypesSelected event, Emitter<WalletCreationState> emit) {
    final current = state;
    if (current is! WalletCreationChainSelection) return;

    emit(current.copyWith(selectedTypes: current.allWalletTypes));
  }

  void _onChainSelectionConfirmed(
    OmniChainWalletChainSelectionConfirmed event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationChainSelection || !current.hasAnySelected) return;

    emit(WalletCreationCustomization(
      selectedTypes: Set<WalletType>.unmodifiable(current.selectedTypes),
    ));
  }

  /// Restores the chain-selection step (e.g. when the user navigates back
  /// events are only handled while the bloc is in [WalletCreationChainSelection].
  void _onChainSelectionReopened(
    OmniChainWalletChainSelectionReopened event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;

    final Set<WalletType> selectedTypes;
    switch (current) {
      case WalletCreationChainSelection _:
        return; // already there, nothing to do
      case WalletCreationCustomization customization:
        selectedTypes = customization.selectedTypes;
      case WalletCreationSummary summary:
        selectedTypes = summary.selectedTypes;
      case WalletCreationOpeningNetwork openingNetwork:
        selectedTypes = openingNetwork.selectedTypes;
      case WalletCreationCreating creating:
        selectedTypes = creating.request.selectedTypes;
      case WalletCreationSeedBackup _:
        return; // group already created — no going back
      case WalletCreated _:
        return;
    }

    emit(
        WalletCreationChainSelection(allWalletTypes: allWalletTypes, selectedTypes: selectedTypes));
  }

  // ---- Step 2: customization ----

  void _onGroupNameChanged(
    OmniChainWalletGroupNameChanged event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationCustomization) return;

    final groupName = event.groupName;

    emit(current.copyWith(
      groupName: groupName,
      groupNameError: _validateGroupName(groupName),
    ));
  }

  Future<void> _onGroupNameGenerated(
    OmniChainWalletGroupNameGenerated event,
    Emitter<WalletCreationState> emit,
  ) async {
    if (state is! WalletCreationCustomization) return;

    final groupName = await generateName();

    final current = state;
    if (current is! WalletCreationCustomization) return;

    emit(current.copyWith(
      groupName: groupName,
      groupNameError: _validateGroupName(groupName),
    ));
  }

  void _onCredentialsSubmitted(
    OmniChainWalletCredentialsSubmitted event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationCustomization || !current.canContinue) return;

    emit(WalletCreationSummary(
      selectedTypes: current.selectedTypes,
      groupName: current.groupName.trim(),
      providedPassphrase: current.providedPassphrase,
      useTestnet: current.useTestnet,
      zcashNetwork: current.zcashNetwork,
    ));
  }

  void _onTestnetToggled(
    OmniChainWalletTestnetToggled event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationCustomization) return;

    emit(current.copyWith(useTestnet: event.value ?? !current.useTestnet));
  }

  void _onZcashNetworkChanged(
    OmniChainWalletZcashNetworkChanged event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationCustomization) return;

    emit(current.copyWith(zcashNetwork: event.network));
  }

  // ---- Step 3: summary ----

  void _onSummaryConfirmed(
    OmniChainWalletSummaryConfirmed event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationSummary) return;

    final singleType = current.selectedTypes.length == 1 ? current.selectedTypes.first : null;

    emit(WalletCreationOpeningNetwork(
      selectedTypes: current.selectedTypes,
      groupName: current.groupName,
      primaryType: singleType,
      providedPassphrase: current.providedPassphrase,
      useTestnet: current.useTestnet,
      zcashNetwork: current.zcashNetwork,
    ));

    if (singleType != null) {
      add(OmniChainWalletGroupCreateRequested());
    }
  }

  // ---- Step 4: opening network / creation ----

  void _onPrimaryTypeSelected(
      OmniChainWalletPrimaryTypeSelected event, Emitter<WalletCreationState> emit) {
    final current = state;
    if (current is! WalletCreationOpeningNetwork) return;
    if (!current.selectedTypes.contains(event.type)) return;

    emit(current.copyWith(primaryType: event.type, creationError: null));
  }

  Future<void> _onGroupCreateRequested(
    OmniChainWalletGroupCreateRequested event,
    Emitter<WalletCreationState> emit,
  ) async {
    final current = state;
    if (current is! WalletCreationOpeningNetwork || !current.canCreate) return;

    emit(WalletCreationCreating(request: current));

    try {
      await creationService.createGroup(
        request: OmniChainCreateGroupRequest(
          selectedTypes: current.selectedTypes,
          primaryType: current.primaryType!,
          groupName: current.groupName,
          passphrase: current.providedPassphrase,
          useTestnet: current.useTestnet,
          zcashNetwork: current.zcashNetwork,
        ),
      );

      emit(WalletCreationSeedBackup(
        groupName: current.groupName,
        selectedTypes: current.selectedTypes,
        primaryType: current.primaryType!,
      ));
    } catch (e) {
      emit(current.copyWith(creationError: e.toString()));
    }
  }

  // ---- Helpers ----

  String? _validateGroupName(String groupName) {
    final trimmedGroupName = groupName.trim();

    if (trimmedGroupName.isEmpty) {
      return 'Group name is required';
    }

    final lengthOrPatternError = WalletNameValidator()(trimmedGroupName);
    if (lengthOrPatternError != null) {
      return lengthOrPatternError;
    }

    if (creationService.groupNameExists(trimmedGroupName)) {
      return 'Group name already exists';
    }

    return null;
  }
}
