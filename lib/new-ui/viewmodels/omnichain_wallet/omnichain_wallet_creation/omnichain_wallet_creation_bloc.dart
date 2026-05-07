import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/wallet_type.dart';

class OmniChainWalletBloc extends Bloc<OmniChainWalletEvent, OmniChainWalletState> {
  OmniChainWalletBloc({
    required Set<WalletType> allWalletTypes,
    required this.creationService,
  }) : super(OmniChainWalletState(allWalletTypes: allWalletTypes)) {
    on<OmniChainWalletTypeToggled>(_onWalletTypeToggled);
    on<OmniChainWalletPrimaryTypeSelected>(_onPrimaryTypeSelected);
    on<OmniChainWalletTypesDeselected>(_onWalletTypesDeselected);
    on<OmniChainWalletTypesSelected>(_onWalletTypesSelected);
    on<OmniChainWalletGroupNameChanged>(_onGroupNameChanged);
    on<OmniChainWalletGroupNameGenerated>(_onGroupNameGenerated);
    on<OmniChainWalletGroupCreateRequested>(_onGroupCreateRequested);
  }

  final OmniChainWalletCreationService creationService;

  void _onWalletTypeToggled(OmniChainWalletTypeToggled event, Emitter<OmniChainWalletState> emit) {
    final updatedSelectedTypes = Set<WalletType>.from(state.selectedTypes);
    if (event.isSelected) {
      updatedSelectedTypes.add(event.type);
    } else {
      updatedSelectedTypes.remove(event.type);
    }

    emit(state.copyWith(selectedTypes: updatedSelectedTypes));
  }

  void _onPrimaryTypeSelected(
      OmniChainWalletPrimaryTypeSelected event, Emitter<OmniChainWalletState> emit) {
    if (!state.selectedTypes.contains(event.type)) return;

    emit(state.copyWith(primaryType: event.type));
  }

  void _onWalletTypesDeselected(
      OmniChainWalletTypesDeselected event, Emitter<OmniChainWalletState> emit) {
    emit(state.copyWith(
      selectedTypes: <WalletType>{},
      primaryType: null,
    ));
  }

  void _onWalletTypesSelected(
      OmniChainWalletTypesSelected event, Emitter<OmniChainWalletState> emit) {
    emit(state.copyWith(
      selectedTypes: Set<WalletType>.from(state.allWalletTypes),
    ));
  }

  void _onGroupNameChanged(
    OmniChainWalletGroupNameChanged event,
    Emitter<OmniChainWalletState> emit,
  ) {
    final groupName = event.groupName.trim();
    String? error;

    if (groupName.isEmpty) {
      error = 'Group name is required';
    } else if (creationService.groupNameExists(groupName)) {
      error = 'Group name already exists';
    }

    emit(state.copyWith(
      groupName: groupName,
      groupNameError: error,
    ));
  }

  Future<void> _onGroupNameGenerated(
    OmniChainWalletGroupNameGenerated event,
    Emitter<OmniChainWalletState> emit,
  ) async {
    final groupName = await generateName();
    String? error;

    if (groupName.trim().isEmpty) {
      error = 'Group name is required';
    } else if (creationService.groupNameExists(groupName)) {
      error = 'Group name already exists';
    }

    emit(state.copyWith(
      groupName: groupName,
      groupNameError: error,
    ));
  }

  Future<void> _onGroupCreateRequested(
    OmniChainWalletGroupCreateRequested event,
    Emitter<OmniChainWalletState> emit,
  ) async {
    try {
      final primaryType = state.primaryType;
      if (primaryType == null) throw Exception('Primary wallet type is not selected');

      final createGroupRequest = OmniChainCreateGroupRequest(
        selectedTypes: state.selectedTypes,
        primaryType: primaryType,
        groupName: state.groupName,
        mnemonic: state.providedMnemonic,
        passphrase: state.providedPassphrase,
      );

      await creationService.createGroup(request: createGroupRequest);

      emit(state.copyWith(
        groupNameError: null,
        groupCreated: true,
      ));
    } catch (e) {
      emit(state.copyWith(groupNameError: e.toString()));
    }
  }

  List<WalletType> popularWalletTypes([Iterable<WalletType>? types]) {
    return (types ?? state.allWalletTypes).where((type) => _popularTypes.contains(type)).toList();
  }

  static const _popularTypes = {
    WalletType.monero,
    WalletType.bitcoin,
    WalletType.ethereum,
    WalletType.litecoin,
    WalletType.zcash,
    WalletType.solana,
    WalletType.tron,
    WalletType.dogecoin,
    WalletType.bsc,
    WalletType.bitcoinCash,
  };
}
