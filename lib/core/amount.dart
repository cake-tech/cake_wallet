// abstract class Amount {
//   Amount(this.value);

//   int value;

//   int minorDigits;

//   String code;

//   String formatted();
// }

// class MoneroAmount extends Amount {
//   MoneroAmount(int value) : super(value) {
//     minorDigits = 12;
//     code = 'XMR';
//   }

//   // const moneroAmountLength = 12;
//   // const moneroAmountDivider = 1000000000000;
//   // final moneroAmountFormat = NumberFormat()
//   //   ..maximumFractionDigits = moneroAmountLength
//   //   ..minimumFractionDigits = 1;

//   // String moneroAmountToString({int amount}) =>
//   //     moneroAmountFormat.format(cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider));

//   // double moneroAmountToDouble({int amount}) => cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider);

//   // int moneroParseAmount({String amount}) => moneroAmountFormat.parse(amount).toInt();

//   @override
//   String formatted() {
//     // TODO: implement formatted
//     throw UnimplementedError();
//   }
// }
