part of "coin_control_bloc.dart";

@immutable
class CoinRow {
  const CoinRow({
    required this.id,
    required this.txHash,
    required this.address,
    required this.amount,
    required this.note,
    required this.isSelected,
    required this.isFrozen,
    required this.isChange,
    required this.isSilentPayment,
  });

  final String id;
  final String txHash;
  final String address;
  final Money amount;
  final String note;
  final bool isSelected;
  final bool isFrozen;
  final bool isChange;
  final bool isSilentPayment;

  CoinRow copyWith({
    String? note,
    bool? isSelected,
    bool? isFrozen,
  }) =>
      CoinRow(
        id: id,
        txHash: txHash,
        address: address,
        amount: amount,
        note: note ?? this.note,
        isSelected: isSelected ?? this.isSelected,
        isFrozen: isFrozen ?? this.isFrozen,
        isChange: isChange,
        isSilentPayment: isSilentPayment,
      );

  @override
  bool operator ==(Object other) =>
      other is CoinRow &&
      other.id == id &&
      other.note == note &&
      other.isSelected == isSelected &&
      other.isFrozen == isFrozen;

  @override
  int get hashCode => Object.hash(id, note, isSelected, isFrozen);
}

@immutable
sealed class CoinControlState {
  const CoinControlState();
}

final class CoinControlLoading extends CoinControlState {
  const CoinControlLoading();
}

final class CoinControlLoaded extends CoinControlState {
  const CoinControlLoaded({required this.rows});

  final List<CoinRow> rows;

  List<CoinRow> get selectable => rows.where((row) => !row.isFrozen).toList();

  List<CoinRow> get frozen => rows.where((row) => row.isFrozen).toList();

  bool get isAllSelected => selectable.every((row) => row.isFrozen || row.isSelected);

  CoinSelection get selection => isAllSelected
      ? const AllCoinSelection()
      : SpecificCoinSelection(rows.where((row) => row.isSelected).map((row) => row.id));

  CoinRow? rowFor(String id) => rows.firstWhereOrNull((item) => item.id == id);

  CoinControlLoaded copyWith({List<CoinRow>? rows}) => CoinControlLoaded(rows: rows ?? this.rows);

  CoinControlLoaded withRow(CoinRow updated) => copyWith(
        rows: rows.map((row) => row.id == updated.id ? updated : row).toList(),
      );
}

final class CoinControlSaved extends CoinControlState {
  const CoinControlSaved(this.selection);

  final CoinSelection selection;
}

final class CoinControlFailure extends CoinControlState {
  const CoinControlFailure(this.error, this.st);

  final Object error;
  final StackTrace st;
}
