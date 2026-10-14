import "package:bloc/bloc.dart";
import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/entities/wallet_group_service.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_group_edit/wallet_group_edit_event.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_group_edit/wallet_group_edit_state.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_service.dart";
import "package:cw_core/wallet_type.dart";


class WalletEditBloc extends Bloc<WalletEditEvent, WalletEditState> {
  WalletEditBloc({
    required this.groupService,
    required this.walletServiceFactory,
  }) : super(WalletEditState()) {
    on<WalletEditStarted>(_onStarted);
    on<WalletEditNameChanged>(_onNameChanged);
    on<WalletEditRenameSubmitted>(_onRenameSubmitted);
    on<WalletEditIconChanged>(_onIconChanged);
  }

  final WalletGroupService groupService;
  final WalletService Function(WalletType type) walletServiceFactory;

  Future<void> _onStarted(
      WalletEditStarted event,
      Emitter<WalletEditState> emit,
      ) async {
    final initial = _findGroup(groupService.groups, event.groupKey);
    emit(state.copyWith(
      groupKey: event.groupKey,
      group: initial,
      name: initial?.groupName ?? "",
      error: null,
    ));

    await emit.forEach<List<WalletGroup>>(
      groupService.watch(),
      onData: (groups) => state.copyWith(group: _findGroup(groups, event.groupKey)),
    );
  }

  void _onNameChanged(
      WalletEditNameChanged event,
      Emitter<WalletEditState> emit,
      ) {
    emit(state.copyWith(name: event.name, error: null));
  }

  Future<void> _onRenameSubmitted(
      WalletEditRenameSubmitted event,
      Emitter<WalletEditState> emit,
      ) async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(error: WalletEditError.nameEmpty));
      return;
    }

    try {
      if (await groupService.isGroupNameTaken(name, excludeGroupKey: state.groupKey)) {
        emit(state.copyWith(error: WalletEditError.nameTaken));
        return;
      }

      await groupService.setGroupName(state.groupKey, name); // one UPDATE
      emit(state.copyWith(error: null, closeRequested: true));
    } catch (e, s) {
      printV("Rename failed for group ${state.groupKey}: $e\n$s");
      emit(state.copyWith(error: WalletEditError.renameFailed));
    }
  }

  Future<void> _onIconChanged(
      WalletEditIconChanged event,
      Emitter<WalletEditState> emit,
      ) async {
    try {
      await groupService.setGroupIcon(state.groupKey, event.icon); // one UPDATE
      emit(state.copyWith(error: null));
    } catch (e, s) {
      printV("Icon change failed for group ${state.groupKey}: $e\n$s");
      emit(state.copyWith(error: WalletEditError.iconFailed));
    }
  }


  WalletGroup? _findGroup(List<WalletGroup> groups, String groupKey) {
    for (final g in groups) {
      if (g.groupKey == groupKey) return g;
    }
    return null;
  }
}