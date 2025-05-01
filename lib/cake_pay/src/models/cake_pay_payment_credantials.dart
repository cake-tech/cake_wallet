class PaymentCredential {
  final double amount;
  final int quantity;
  final double totalAmount;
  final String? userName;
  final String fiatCurrency;

  PaymentCredential({
    required this.amount,
    required this.quantity,
    required this.totalAmount,
    required this.userName,
    required this.fiatCurrency,
  });
}