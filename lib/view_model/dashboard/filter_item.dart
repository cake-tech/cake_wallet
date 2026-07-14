import 'package:cake_wallet/exchange/exchange_provider_description.dart';

class FilterItem {
  FilterItem({required this.value, required this.caption, required this.onChanged});

  bool Function() value;
  String caption;
  Function onChanged;
}

class SwapFilterItem extends FilterItem {
  SwapFilterItem({
    required this.enabledProviders,
    required this.allEnabled,
    required super.value,
    super.caption = "Swap",
    required super.onChanged,
  });

  int Function() enabledProviders;
  bool Function() allEnabled;
}

class SwapProviderFilterItem extends FilterItem {
  SwapProviderFilterItem(
      {required super.value,
      required super.onChanged,
      required this.providerDescription,
      super.caption = ""});

  @override
  String get caption => providerDescription.title;

  final ExchangeProviderDescription providerDescription;
}
