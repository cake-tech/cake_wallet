/// Empty memos are not a deposit tag. 1Click only needs the memo when the
/// quote was a shared Stellar address.
String? nearIntentsDepositMemo(String? depositMemo) {
  final memo = depositMemo?.trim();
  if (memo == null || memo.isEmpty) {
    return null;
  }
  return memo;
}

Map<String, String> nearIntentsStatusQuery({
  required String depositAddress,
  String? depositMemo,
}) {
  final query = <String, String>{'depositAddress': depositAddress};
  final memo = nearIntentsDepositMemo(depositMemo);
  if (memo != null) {
    query['depositMemo'] = memo;
  }
  return query;
}
