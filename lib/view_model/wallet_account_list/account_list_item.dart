class AccountListItem {
  AccountListItem({required this.label, required this.id, this.balance, this.isSelected = false});

  final String label;
  final int id;
  final bool isSelected;
  final String? balance;

  bool get isFunded {
    if (balance?.contains("●") ?? false) {
      return true;
    }
    return (double.tryParse(balance?.trim().replaceAll(",", "") ?? "") ?? 0) > 0;
  }
}
