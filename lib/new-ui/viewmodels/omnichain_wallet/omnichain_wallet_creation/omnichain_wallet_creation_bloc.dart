import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/entries/omnichain_wallet/omnichain_create_group_request.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';

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
    on<OmniChainWalletTypesSelectionChanged>(_onWalletTypesSelectionChanged);
  }

  final OmniChainWalletCreationService creationService;

  void _onWalletTypeToggled(OmniChainWalletTypeToggled event, Emitter<OmniChainWalletState> emit) {
    final updatedSelectedTypes = Set<WalletType>.from(state.selectedTypes);
    final isBip39Type = isBIP39Wallet(event.type);

    if (event.isSelected) {
      if (isBip39Type) {
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

    emit(state.copyWith(
      selectedTypes: updatedSelectedTypes,
      primaryType: updatedSelectedTypes.contains(state.primaryType) ? state.primaryType : null,
    ));
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
      selectedTypes: state.allWalletTypes.where((type) => isBIP39Wallet(type)).toSet(),
      primaryType: state.primaryType != null && isBIP39Wallet(state.primaryType!)
          ? state.primaryType
          : null,
    ));
  }

  void _onWalletTypesSelectionChanged(
    OmniChainWalletTypesSelectionChanged event,
    Emitter<OmniChainWalletState> emit,
  ) {
    final selectedTypes = Set<WalletType>.from(event.selectedTypes);
    final nonBip39Types = selectedTypes.where((type) => !isBIP39Wallet(type)).toList();

    final normalizedSelectedTypes = nonBip39Types.isNotEmpty
        ? <WalletType>{nonBip39Types.last}
        : selectedTypes.where((type) => isBIP39Wallet(type)).toSet();

    emit(state.copyWith(
      selectedTypes: normalizedSelectedTypes,
      primaryType: normalizedSelectedTypes.contains(state.primaryType) ? state.primaryType : null,
    ));
  }

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

  void _onGroupNameChanged(
    OmniChainWalletGroupNameChanged event,
    Emitter<OmniChainWalletState> emit,
  ) {
    final groupName = event.groupName.trim();

    emit(state.copyWith(
      groupName: groupName,
      groupNameError: _validateGroupName(groupName),
    ));
  }

  Future<void> _onGroupNameGenerated(
    OmniChainWalletGroupNameGenerated event,
    Emitter<OmniChainWalletState> emit,
  ) async {
    final groupName = await generateName();

    emit(state.copyWith(
      groupName: groupName,
      groupNameError: _validateGroupName(groupName),
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
    WalletType.solana,
    WalletType.zcash,
    WalletType.base,
    WalletType.arbitrum,
    WalletType.bsc,
  };
}
