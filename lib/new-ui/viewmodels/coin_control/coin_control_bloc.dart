import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/core/utilities.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/coin_control/coin_control_wallet.dart";
import "package:cw_core/coin_control/coin_selection.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:meta/meta.dart";

part "coin_control_event.dart";

part "coin_control_state.dart";

class CoinControlBloc extends Bloc<CoinControlEvent, CoinControlState> {
  CoinControlBloc({
    required this.wallet,
    this.constraint = UnspentCoinType.any,
    CoinSelection initialSelection = const AllCoinSelection(),
  })  : _initialSelection = initialSelection,
        super(const CoinControlLoading()) {
    on<_Init>(_init);
    on<SelectionChanged>(_onSelectionChanged, transformer: sequential());
    on<SelectAllChanged>(_onSelectAllChanged, transformer: sequential());
    on<NoteChanged>(_onNoteChanged, transformer: sequential());
    on<FreezeToggled>(_onFreezeToggled, transformer: sequential());
    on<SelectionSaved>(_onSaved);

    add(const _Init());
  }

  final CoinControlWallet wallet;
  final CoinSelection _initialSelection;
  final UnspentCoinType constraint;

  Future<void> _init(_Init event, Emitter<CoinControlState> emit) async {
    emit(const CoinControlLoading());

    try {
      await wallet.refreshUnspents();

      final frozen = await wallet.frozenIds();
      final notes = await wallet.notes();

      final rows = <CoinRow>[];
      for (final coin in wallet.unspents) {
        if (!wallet.allowsCoinType(coin, constraint)) {
          continue;
        }

        final isFrozen = frozen.contains(coin.id);

        rows.add(
          CoinRow(
            id: coin.id,
            txHash: coin.hash,
            address: coin.address,
            amount: Money.fromInt(coin.value, wallet.currency),
            note: notes[coin.id] ?? "",
            isSelected: !isFrozen && _initialSelection.allows(coin),
            isFrozen: isFrozen,
            isChange: coin.isChange,
            isSilentPayment: coin.isSilentPayment,
          ),
        );
      }

      rows.sort((a, b) => b.amount.amount.compareTo(a.amount.amount));

      emit(CoinControlLoaded(rows: rows));
    } catch (e, st) {
      emit(CoinControlFailure(e, st));
    }
  }

  void _onSelectionChanged(SelectionChanged event, Emitter<CoinControlState> emit) {
    final current = state;
    if (current is! CoinControlLoaded) {
      return;
    }

    final row = current.rowFor(event.id);
    if (row == null || row.isFrozen) {
      return;
    }

    emit(current.withRow(row.copyWith(isSelected: event.value)));
  }

  void _onSelectAllChanged(SelectAllChanged event, Emitter<CoinControlState> emit) {
    final current = state;
    if (current is! CoinControlLoaded) {
      return;
    }

    emit(
      current.copyWith(
        rows: current.rows
            .map((row) => row.isFrozen ? row : row.copyWith(isSelected: event.value))
            .toList(),
      ),
    );
  }

  Future<void> _onNoteChanged(NoteChanged event, Emitter<CoinControlState> emit) async {
    if (state case final CoinControlLoaded s) {
      try {
        await wallet.saveNote(event.id, event.note);

        emit(
          s.withRow(
            s.rowFor(event.id)!.copyWith(
                  note: event.note,
                ),
          ),
        );
      } catch (e, st) {
        emit(CoinControlFailure(e, st));
        return;
      }
    }
  }

  Future<void> _onFreezeToggled(FreezeToggled event, Emitter<CoinControlState> emit) async {
    if (state case final CoinControlLoaded s) {
      try {
        await wallet.setFrozen(event.id, event.value);

        emit(
          s.withRow(
            s.rowFor(event.id)!.copyWith(
                  isFrozen: event.value,
                  isSelected: event.value ? false : null,
                ),
          ),
        );
      } catch (e, st) {
        emit(CoinControlFailure(e, st));
        return;
      }
    }
  }

  void _onSaved(SelectionSaved event, Emitter<CoinControlState> emit) {
    if (state case final CoinControlLoaded s) {
      emit(CoinControlSaved(s.selection));
    }
  }
}
