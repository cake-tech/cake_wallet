class ExchangeTradeItem {
  ExchangeTradeItem({
    required this.title,
    required this.data,
    required this.isCopied,
    required this.isReceiveDetail,
    required this.isExternalSendDetail,
  });

  String title;
  String data;
  bool isCopied;
  bool isReceiveDetail;
  bool isExternalSendDetail;
}