import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_state.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/generate_name.dart';

class OmniChainWalletBloc extends Bloc<OmniChainWalletEvent, OmniChainWalletState> {
  OmniChainWalletBloc({
    required Set<WalletType> allWalletTypes,
  }) : super(OmniChainWalletState(allWalletTypes: allWalletTypes)) {
    on<OmniChainWalletTypeToggled>(_onWalletTypeToggled);
    on<OmniChainWalletTypesDeselected>(_onWalletTypesDeselected);
    on<OmniChainWalletTypesSelected>(_onWalletTypesSelected);
    on<OmniChainWalletNameChanged>(_onWalletNameChanged);
    on<OmniChainWalletNameGenerated>(_onWalletNameGenerated);
  }

  void _onWalletTypeToggled(OmniChainWalletTypeToggled event, Emitter<OmniChainWalletState> emit) {
    final updatedSelectedTypes = Set<WalletType>.from(state.selectedTypes);
    if (event.isSelected) {
      updatedSelectedTypes.add(event.type);
    } else {
      updatedSelectedTypes.remove(event.type);
    }
    emit(state.copyWith(selectedTypes: updatedSelectedTypes));
  }

  void _onWalletTypesDeselected(
      OmniChainWalletTypesDeselected event, Emitter<OmniChainWalletState> emit) {
    emit(state.copyWith(selectedTypes: <WalletType>{}));
  }

  void _onWalletTypesSelected(
      OmniChainWalletTypesSelected event, Emitter<OmniChainWalletState> emit) {
    emit(state.copyWith(
      selectedTypes: Set<WalletType>.from(state.allWalletTypes),
    ));
  }

  void _onWalletNameChanged(
    OmniChainWalletNameChanged event,
    Emitter<OmniChainWalletState> emit,
  ) {
    emit(state.copyWith(name: event.name.trim()));
  }

  Future<void> _onWalletNameGenerated(
    OmniChainWalletNameGenerated event,
    Emitter<OmniChainWalletState> emit,
  ) async {
    final name = await generateName();
    emit(state.copyWith(name: name));
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
