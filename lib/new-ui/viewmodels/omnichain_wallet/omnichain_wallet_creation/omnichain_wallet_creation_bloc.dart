import "package:bloc/bloc.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart";
import "package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/wallet_type.dart";

class OmniChainWalletBloc extends Bloc<OmniChainWalletEvent, WalletCreationState> {
  OmniChainWalletBloc({
    required Set<WalletType> allWalletTypes,
    required this.creationService,
  }) : super(WalletCreationChainSelection(allWalletTypes: allWalletTypes)) {
    on<OmniChainWalletTypeToggled>(_onWalletTypeToggled);
    on<OmniChainWalletTypesDeselected>(_onWalletTypesDeselected);
    on<OmniChainWalletTypesSelected>(_onWalletTypesSelected);
    on<OmniChainWalletChainSelectionConfirmed>(_onChainSelectionConfirmed);
    on<OmniChainWalletGroupNameChanged>(_onGroupNameChanged);
    on<OmniChainWalletGroupNameGenerated>(_onGroupNameGenerated);
    on<OmniChainWalletCredentialsSubmitted>(_onCredentialsSubmitted);
    on<OmniChainWalletSummaryConfirmed>(_onSummaryConfirmed);
    on<OmniChainWalletPrimaryTypeSelected>(_onPrimaryTypeSelected);
    on<OmniChainWalletGroupCreateRequested>(_onGroupCreateRequested);
  }

  final OmniChainWalletCreationService creationService;

  // ---- Step 1: chain selection ----

  void _onWalletTypeToggled(OmniChainWalletTypeToggled event, Emitter<WalletCreationState> emit) {
    final current = state;
    if (current is! WalletCreationChainSelection) {
      return;
    }

    final updatedSelectedTypes = Set<WalletType>.from(current.selectedTypes);

    if (event.isSelected) {
      if (isBIP39Wallet(event.type)) {
        updatedSelectedTypes.removeWhere((type) => !isBIP39Wallet(type));
        updatedSelectedTypes.add(event.type);
      } else {
        updatedSelectedTypes
          ..clear()
          ..add(event.type);
      }
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
    if (current is! WalletCreationChainSelection) {
      return;
    }

    emit(
      current.copyWith(
        selectedTypes: current.allWalletTypes.where(isBIP39Wallet).toSet(),
      ),
    );
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

  // ---- Step 2: customization ----

  void _onGroupNameChanged(
    OmniChainWalletGroupNameChanged event,
    Emitter<WalletCreationState> emit,
  ) {
    final current = state;
    if (current is! WalletCreationCustomization) return;

    final groupName = event.groupName.trim();

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
      groupName: current.groupName,
      providedPassphrase: current.providedPassphrase,
    ));
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
        ),
      );

      emit(WalletCreated(groupName: current.groupName));
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

    final invalidCharacters = RegExp(r'''[\\/:*?"<>|_']''');

    if (invalidCharacters.hasMatch(trimmedGroupName)) {
      return 'Group name contains invalid characters';
    }

    if (creationService.groupNameExists(trimmedGroupName)) {
      return 'Group name already exists';
    }

    return null;
  }
}
